"""
Cryptocurrency service for handling crypto operations and API integrations
"""
import requests
import logging
from decimal import Decimal
from datetime import datetime, timezone
from django.conf import settings
from django.utils import timezone as django_timezone
from ..models import CryptoCurrency, CryptoWallet, CryptoTransaction, CryptoPriceHistory, User, Card

logger = logging.getLogger(__name__)


class CoinGeckoService:
    """Service for interacting with CoinGecko API"""
    
    BASE_URL = "https://api.coingecko.com/api/v3"
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Nyota Bank Crypto Service/1.0'
        })
    
    def get_supported_coins(self):
        """Get list of supported coins from CoinGecko"""
        try:
            response = self.session.get(f"{self.BASE_URL}/coins/list")
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Error fetching supported coins: {e}")
            return []
    
    def get_coin_prices(self, coin_ids, vs_currency='usd'):
        """Get current prices for specified coins"""
        try:
            ids_str = ','.join(coin_ids)
            params = {
                'ids': ids_str,
                'vs_currencies': vs_currency,
                'include_market_cap': 'true',
                'include_24hr_change': 'true',
                'include_last_updated_at': 'true'
            }
            
            response = self.session.get(f"{self.BASE_URL}/simple/price", params=params)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Error fetching coin prices: {e}")
            return {}
    
    def get_coin_history(self, coin_id, days=7):
        """Get historical price data for a coin"""
        try:
            params = {
                'vs_currency': 'usd',
                'days': days,
                'interval': 'daily' if days > 1 else 'hourly'
            }
            
            response = self.session.get(f"{self.BASE_URL}/coins/{coin_id}/market_chart", params=params)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Error fetching coin history for {coin_id}: {e}")
            return {}


class CryptoService:
    """Main service for cryptocurrency operations"""
    
    def __init__(self):
        self.coingecko = CoinGeckoService()
    
    def initialize_popular_cryptocurrencies(self):
        """Initialize popular cryptocurrencies in the database"""
        popular_cryptos = [
            {
                'id': 'bitcoin',
                'symbol': 'BTC',
                'name': 'Bitcoin',
                'icon_url': 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png'
            },
            {
                'id': 'ethereum',
                'symbol': 'ETH',
                'name': 'Ethereum',
                'icon_url': 'https://assets.coingecko.com/coins/images/279/large/ethereum.png'
            },
            {
                'id': 'tether',
                'symbol': 'USDT',
                'name': 'Tether',
                'icon_url': 'https://assets.coingecko.com/coins/images/325/large/Tether.png'
            },
            {
                'id': 'binancecoin',
                'symbol': 'BNB',
                'name': 'BNB',
                'icon_url': 'https://assets.coingecko.com/coins/images/825/large/bnb-icon2_2x.png'
            },
            {
                'id': 'solana',
                'symbol': 'SOL',
                'name': 'Solana',
                'icon_url': 'https://assets.coingecko.com/coins/images/4128/large/solana.png'
            },
            {
                'id': 'usd-coin',
                'symbol': 'USDC',
                'name': 'USD Coin',
                'icon_url': 'https://assets.coingecko.com/coins/images/6319/large/USD_Coin_icon.png'
            },
            {
                'id': 'cardano',
                'symbol': 'ADA',
                'name': 'Cardano',
                'icon_url': 'https://assets.coingecko.com/coins/images/975/large/cardano.png'
            },
            {
                'id': 'dogecoin',
                'symbol': 'DOGE',
                'name': 'Dogecoin',
                'icon_url': 'https://assets.coingecko.com/coins/images/5/large/dogecoin.png'
            }
        ]
        
        created_count = 0
        for crypto_data in popular_cryptos:
            crypto, created = CryptoCurrency.objects.get_or_create(
                id=crypto_data['id'],
                defaults=crypto_data
            )
            if created:
                created_count += 1
                logger.info(f"Created cryptocurrency: {crypto.symbol}")
        
        logger.info(f"Initialized {created_count} new cryptocurrencies")
        return created_count
    
    def update_crypto_prices(self):
        """Update prices for all active cryptocurrencies"""
        active_cryptos = CryptoCurrency.objects.filter(is_active=True)
        if not active_cryptos.exists():
            logger.warning("No active cryptocurrencies found")
            return 0
        
        coin_ids = [crypto.id for crypto in active_cryptos]
        prices_data = self.coingecko.get_coin_prices(coin_ids)
        
        updated_count = 0
        for crypto in active_cryptos:
            if crypto.id in prices_data:
                price_info = prices_data[crypto.id]
                
                crypto.current_price_usd = Decimal(str(price_info.get('usd', 0)))
                crypto.market_cap = price_info.get('usd_market_cap', 0)
                crypto.price_change_24h = Decimal(str(price_info.get('usd_24h_change', 0)))
                crypto.last_updated = django_timezone.now()
                crypto.save()
                
                # Save historical data
                CryptoPriceHistory.objects.create(
                    cryptocurrency=crypto,
                    price_usd=crypto.current_price_usd,
                    market_cap=crypto.market_cap,
                    timestamp=crypto.last_updated
                )
                
                updated_count += 1
                logger.info(f"Updated price for {crypto.symbol}: ${crypto.current_price_usd}")
        
        logger.info(f"Updated prices for {updated_count} cryptocurrencies")
        return updated_count
    
    def create_wallet(self, user, cryptocurrency_id):
        """Create a new crypto wallet for user"""
        try:
            cryptocurrency = CryptoCurrency.objects.get(id=cryptocurrency_id, is_active=True)
        except CryptoCurrency.DoesNotExist:
            raise ValueError("Cryptocurrency not found or inactive")
        
        wallet, created = CryptoWallet.objects.get_or_create(
            user=user,
            cryptocurrency=cryptocurrency,
            defaults={'wallet_address': ''}
        )
        
        if created:
            wallet.wallet_address = wallet.generate_wallet_address()
            wallet.save()
            logger.info(f"Created wallet for {user.phone_number}: {cryptocurrency.symbol}")
        
        return wallet
    
    def buy_cryptocurrency(self, user, cryptocurrency_id, usd_amount):
        """Buy cryptocurrency with USD from user's card"""
        try:
            cryptocurrency = CryptoCurrency.objects.get(id=cryptocurrency_id, is_active=True)
        except CryptoCurrency.DoesNotExist:
            raise ValueError("Cryptocurrency not found")
        
        # Get user's default card
        user_card = user.get_default_card()
        if not user_card:
            raise ValueError("No default card found")
        
        if not user_card.is_active:
            raise ValueError("Card is blocked")
        
        if user_card.balance < usd_amount:
            raise ValueError("Insufficient funds on card")
        
        # Calculate crypto amount
        if cryptocurrency.current_price_usd <= 0:
            raise ValueError("Invalid cryptocurrency price")
        
        crypto_amount = usd_amount / cryptocurrency.current_price_usd
        fee_amount = usd_amount * Decimal('0.01')  # 1% fee
        total_amount = usd_amount + fee_amount
        
        if user_card.balance < total_amount:
            raise ValueError("Insufficient funds including fees")
        
        # Create or get wallet
        wallet = self.create_wallet(user, cryptocurrency_id)
        
        # Create transaction
        transaction = CryptoTransaction.objects.create(
            user=user,
            wallet=wallet,
            transaction_type='buy',
            status='pending',
            crypto_amount=crypto_amount,
            usd_amount=usd_amount,
            fee_amount=fee_amount,
            exchange_rate=cryptocurrency.current_price_usd
        )
        
        # Process transaction
        try:
            # Deduct from card
            user_card.balance -= total_amount
            user_card.save()
            
            # Add to crypto wallet
            wallet.balance += crypto_amount
            wallet.save()
            
            # Update transaction
            transaction.status = 'completed'
            transaction.completed_at = django_timezone.now()
            transaction.transaction_hash = transaction.generate_transaction_hash()
            transaction.save()
            
            logger.info(f"Buy transaction completed: {user.phone_number} bought {crypto_amount} {cryptocurrency.symbol}")
            return transaction
            
        except Exception as e:
            transaction.status = 'failed'
            transaction.notes = str(e)
            transaction.save()
            logger.error(f"Buy transaction failed: {e}")
            raise
    
    def sell_cryptocurrency(self, user, wallet_id, crypto_amount):
        """Sell cryptocurrency and add USD to user's card"""
        try:
            wallet = CryptoWallet.objects.get(id=wallet_id, user=user, is_active=True)
        except CryptoWallet.DoesNotExist:
            raise ValueError("Wallet not found")
        
        if wallet.balance < crypto_amount:
            raise ValueError("Insufficient crypto balance")
        
        # Get user's default card
        user_card = user.get_default_card()
        if not user_card:
            raise ValueError("No default card found")
        
        # Calculate USD amount
        cryptocurrency = wallet.cryptocurrency
        if cryptocurrency.current_price_usd <= 0:
            raise ValueError("Invalid cryptocurrency price")
        
        usd_amount = crypto_amount * cryptocurrency.current_price_usd
        fee_amount = usd_amount * Decimal('0.01')  # 1% fee
        net_usd_amount = usd_amount - fee_amount
        
        # Create transaction
        transaction = CryptoTransaction.objects.create(
            user=user,
            wallet=wallet,
            transaction_type='sell',
            status='pending',
            crypto_amount=crypto_amount,
            usd_amount=net_usd_amount,
            fee_amount=fee_amount,
            exchange_rate=cryptocurrency.current_price_usd
        )
        
        # Process transaction
        try:
            # Deduct from crypto wallet
            wallet.balance -= crypto_amount
            wallet.save()
            
            # Add to card
            user_card.balance += net_usd_amount
            user_card.save()
            
            # Update transaction
            transaction.status = 'completed'
            transaction.completed_at = django_timezone.now()
            transaction.transaction_hash = transaction.generate_transaction_hash()
            transaction.save()
            
            logger.info(f"Sell transaction completed: {user.phone_number} sold {crypto_amount} {cryptocurrency.symbol}")
            return transaction
            
        except Exception as e:
            transaction.status = 'failed'
            transaction.notes = str(e)
            transaction.save()
            logger.error(f"Sell transaction failed: {e}")
            raise
    
    def transfer_cryptocurrency(self, user, wallet_id, to_address, crypto_amount):
        """Transfer cryptocurrency to another address"""
        try:
            wallet = CryptoWallet.objects.get(id=wallet_id, user=user, is_active=True)
        except CryptoWallet.DoesNotExist:
            raise ValueError("Wallet not found")
        
        if wallet.balance < crypto_amount:
            raise ValueError("Insufficient crypto balance")
        
        if to_address == wallet.wallet_address:
            raise ValueError("Cannot transfer to own address")
        
        # Calculate fee (0.1% of current USD value)
        cryptocurrency = wallet.cryptocurrency
        usd_value = crypto_amount * cryptocurrency.current_price_usd
        fee_amount = usd_value * Decimal('0.001')
        
        # Create transaction
        transaction = CryptoTransaction.objects.create(
            user=user,
            wallet=wallet,
            transaction_type='transfer_out',
            status='pending',
            crypto_amount=crypto_amount,
            usd_amount=usd_value,
            fee_amount=fee_amount,
            exchange_rate=cryptocurrency.current_price_usd,
            from_address=wallet.wallet_address,
            to_address=to_address
        )
        
        # Process transaction
        try:
            # Deduct from wallet
            wallet.balance -= crypto_amount
            wallet.save()
            
            # Update transaction
            transaction.status = 'completed'
            transaction.completed_at = django_timezone.now()
            transaction.transaction_hash = transaction.generate_transaction_hash()
            transaction.save()
            
            logger.info(f"Transfer completed: {user.phone_number} sent {crypto_amount} {cryptocurrency.symbol}")
            return transaction
            
        except Exception as e:
            transaction.status = 'failed'
            transaction.notes = str(e)
            transaction.save()
            logger.error(f"Transfer failed: {e}")
            raise
    
    def get_user_portfolio(self, user):
        """Get user's crypto portfolio summary"""
        wallets = CryptoWallet.objects.filter(user=user, is_active=True).select_related('cryptocurrency')
        
        total_balance_usd = Decimal('0')
        total_change_24h = Decimal('0')
        portfolio_data = []
        
        for wallet in wallets:
            if wallet.balance > 0:
                balance_usd = wallet.balance_usd
                total_balance_usd += balance_usd
                
                # Calculate 24h change for this holding
                crypto = wallet.cryptocurrency
                if crypto.current_price_usd > 0:
                    change_24h = wallet.balance * crypto.price_change_24h
                    total_change_24h += change_24h
                
                portfolio_data.append({
                    'symbol': crypto.symbol,
                    'name': crypto.name,
                    'balance': wallet.balance,
                    'balance_usd': balance_usd,
                    'percentage': 0  # Will calculate after total
                })
        
        # Calculate percentages
        for item in portfolio_data:
            if total_balance_usd > 0:
                item['percentage'] = round((item['balance_usd'] / total_balance_usd) * 100, 2)
        
        # Calculate total change percentage
        total_change_percent = Decimal('0')
        if total_balance_usd > 0:
            total_change_percent = (total_change_24h / total_balance_usd) * 100
        
        # Sort by balance USD descending
        portfolio_data.sort(key=lambda x: x['balance_usd'], reverse=True)
        
        return {
            'total_balance_usd': total_balance_usd,
            'total_change_24h': total_change_24h,
            'total_change_percent': total_change_percent,
            'wallets': wallets,
            'top_holdings': portfolio_data[:5]  # Top 5 holdings
        } 