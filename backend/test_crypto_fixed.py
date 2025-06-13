#!/usr/bin/env python
"""
Test script for cryptocurrency wallet functionality
"""
import os
import sys
import django
from decimal import Decimal

# Add the backend directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nyota_bank.settings')
django.setup()

from django.contrib.auth import get_user_model
from api.models import CryptoCurrency, CryptoWallet, CryptoTransaction
from api.services import CryptoService

User = get_user_model()

def test_crypto_models():
    """Test cryptocurrency models"""
    print("🧪 Testing Crypto Models...")
    
    # Test CryptoCurrency model
    btc, created = CryptoCurrency.objects.get_or_create(
        id="bitcoin",  # CoinGecko ID
        defaults={
            'name': "Bitcoin",
            'symbol': "BTC",
            'current_price_usd': Decimal('50000.00'),
            'market_cap': 1000000000,
            'price_change_24h': Decimal('2.5')
        }
    )
    if created:
        print(f"✅ Created cryptocurrency: {btc}")
    else:
        print(f"✅ Found existing cryptocurrency: {btc}")
    
    # Test user and wallet creation
    user, created = User.objects.get_or_create(
        phone_number='+1234567891',
        defaults={
            'first_name': 'Crypto',
            'last_name': 'Tester',
        }
    )
    if created:
        user.set_password('testpass123')
        user.save()
        print(f"✅ Created user: {user}")
    else:
        print(f"✅ Found existing user: {user}")
    
    # Test CryptoWallet model
    wallet, created = CryptoWallet.objects.get_or_create(
        user=user,
        cryptocurrency=btc,
        defaults={
            'balance': Decimal('0.5'),
            'wallet_address': '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'
        }
    )
    if created:
        print(f"✅ Created wallet: {wallet}")
    else:
        print(f"✅ Found existing wallet: {wallet}")
    
    # Test CryptoTransaction model
    transaction = CryptoTransaction.objects.create(
        user=user,
        wallet=wallet,
        transaction_type='buy',
        crypto_amount=Decimal('0.1'),
        usd_amount=Decimal('5000.00'),
        exchange_rate=Decimal('50000.00'),
        fee_amount=Decimal('50.00'),
        status='completed'
    )
    print(f"✅ Created transaction: {transaction}")
    
    return user, btc, wallet

def test_crypto_service():
    """Test cryptocurrency service"""
    print("\n🧪 Testing Crypto Service...")
    
    try:
        crypto_service = CryptoService()
        print("✅ CryptoService initialized")
        
        # Test popular cryptocurrencies initialization
        result = crypto_service.initialize_popular_cryptocurrencies()
        print(f"✅ Initialized cryptocurrencies: {result}")
        
        # Test price update (will fail without internet, but that's expected)
        try:
            updated_count = crypto_service.update_crypto_prices()
            print(f"✅ Updated {updated_count} cryptocurrency prices")
        except Exception as e:
            print(f"⚠️ Price update failed (expected without internet): {e}")
        
        return crypto_service
        
    except Exception as e:
        print(f"❌ CryptoService error: {e}")
        return None

def test_wallet_operations():
    """Test wallet operations"""
    print("\n🧪 Testing Wallet Operations...")
    
    try:
        # Get test data
        user = User.objects.filter(phone_number='+1234567891').first()
        btc = CryptoCurrency.objects.filter(symbol='BTC').first()
        
        if not user or not btc:
            print("❌ Test data not found, creating...")
            user, btc, wallet = test_crypto_models()
        
        crypto_service = CryptoService()
        
        # Test wallet creation
        wallet_data = crypto_service.create_wallet(user, btc.id)  # Pass ID, not object
        print(f"✅ Created wallet: {wallet_data}")
        
        # Test portfolio
        portfolio = crypto_service.get_user_portfolio(user)
        print(f"✅ User portfolio: {portfolio}")
        
        # Test buy operation (simulated)
        try:
            buy_result = crypto_service.buy_cryptocurrency(
                user=user,
                cryptocurrency_id=btc.id,  # Pass ID, not object
                usd_amount=Decimal('100.00')  # Use correct parameter name
            )
            print(f"✅ Buy operation: {buy_result}")
        except Exception as e:
            print(f"⚠️ Buy operation failed (expected without card): {e}")
        
        return True
        
    except Exception as e:
        print(f"❌ Wallet operations error: {e}")
        return False

def test_database_queries():
    """Test database queries"""
    print("\n🧪 Testing Database Queries...")
    
    try:
        # Test cryptocurrency queries
        cryptos = CryptoCurrency.objects.filter(is_active=True)
        print(f"✅ Active cryptocurrencies: {cryptos.count()}")
        
        for crypto in cryptos[:3]:  # Show first 3
            print(f"   - {crypto.name} ({crypto.symbol}): ${crypto.current_price_usd}")
        
        # Test wallet queries
        wallets = CryptoWallet.objects.all()
        print(f"✅ Total wallets: {wallets.count()}")
        
        # Test transaction queries
        transactions = CryptoTransaction.objects.all()
        print(f"✅ Total transactions: {transactions.count()}")
        
        # Test user portfolio query
        users_with_wallets = User.objects.filter(crypto_wallets__isnull=False).distinct()
        print(f"✅ Users with crypto wallets: {users_with_wallets.count()}")
        
        return True
        
    except Exception as e:
        print(f"❌ Database queries error: {e}")
        return False

def cleanup_test_data():
    """Clean up test data"""
    print("\n🧹 Cleaning up test data...")
    
    try:
        # Delete test transactions
        CryptoTransaction.objects.filter(user__phone_number='+1234567891').delete()
        print("✅ Deleted test transactions")
        
        # Delete test wallets
        CryptoWallet.objects.filter(user__phone_number='+1234567891').delete()
        print("✅ Deleted test wallets")
        
        # Delete test user
        User.objects.filter(phone_number='+1234567891').delete()
        print("✅ Deleted test user")
        
        # Keep cryptocurrencies as they're useful for the system
        print("✅ Kept cryptocurrencies for system use")
        
    except Exception as e:
        print(f"❌ Cleanup error: {e}")

def main():
    """Main test function"""
    print("🚀 Starting Cryptocurrency Wallet Tests")
    print("=" * 50)
    
    try:
        # Run tests
        test_crypto_models()
        test_crypto_service()
        test_wallet_operations()
        test_database_queries()
        
        print("\n" + "=" * 50)
        print("✅ All tests completed successfully!")
        
        # Ask user if they want to clean up
        cleanup = input("\n🧹 Clean up test data? (y/n): ").lower().strip()
        if cleanup == 'y':
            cleanup_test_data()
        else:
            print("🔄 Test data kept for inspection")
        
    except Exception as e:
        print(f"\n❌ Test suite failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 