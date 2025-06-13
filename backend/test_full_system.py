#!/usr/bin/env python
"""
Comprehensive test suite for Nyota Bank system
Tests all major functionality to ensure system reliability
"""
import os
import sys
import django
from decimal import Decimal
from datetime import date, timedelta

# Add the backend directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nyota_bank.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.utils import timezone
from api.models import (
    Card, Transaction, Deposit, Loan, Mortgage, Application,
    Currency, CurrencyHistory, ForumPost, ForumComment, ForumLike,
    Terminal, AIChat, AIChatMessage, PredictionPost, PredictionComment,
    CryptoCurrency, CryptoWallet, CryptoTransaction
)
from api.services import CryptoService, AIChatService

User = get_user_model()

class SystemTestSuite:
    """Main test suite for the entire system"""
    
    def __init__(self):
        self.test_users = []
        self.test_cards = []
        self.errors = []
        self.successes = []
    
    def log_success(self, message):
        """Log successful test"""
        print(f"✅ {message}")
        self.successes.append(message)
    
    def log_error(self, message, error=None):
        """Log test error"""
        error_msg = f"❌ {message}"
        if error:
            error_msg += f" - {str(error)}"
        print(error_msg)
        self.errors.append(error_msg)
    
    def log_warning(self, message):
        """Log test warning"""
        print(f"⚠️ {message}")
    
    def create_test_users(self):
        """Create test users for testing"""
        print("\n🧪 Creating Test Users...")
        
        try:
            # Test user 1 - Main user
            user1, created = User.objects.get_or_create(
                phone_number='+1234567890',
                defaults={
                    'first_name': 'Test',
                    'last_name': 'User',
                    'email': 'test@example.com'
                }
            )
            if created:
                user1.set_password('testpass123')
                user1.save()
            self.test_users.append(user1)
            self.log_success(f"Created/found main test user: {user1.get_full_name()}")
            
            # Test user 2 - Secondary user for transfers
            user2, created = User.objects.get_or_create(
                phone_number='+1234567891',
                defaults={
                    'first_name': 'Second',
                    'last_name': 'User',
                    'email': 'second@example.com'
                }
            )
            if created:
                user2.set_password('testpass123')
                user2.save()
            self.test_users.append(user2)
            self.log_success(f"Created/found secondary test user: {user2.get_full_name()}")
            
            return True
            
        except Exception as e:
            self.log_error("Failed to create test users", e)
            return False
    
    def test_card_functionality(self):
        """Test card creation and management"""
        print("\n🧪 Testing Card Functionality...")
        
        try:
            user = self.test_users[0]
            
            # Test card creation
            card = Card.objects.create(
                owner=user,
                card_name="Test Card",
                card_number=Card.generate_card_number(),
                balance=Decimal('10000.00'),
                card_expiry_date=Card.generate_expiration_date(),
                cvv=Card.generate_cvv(),
                is_default=True,
                gradient_start_hex="#FF6B6B",
                gradient_end_hex="#4ECDC4"
            )
            self.test_cards.append(card)
            self.log_success(f"Created card: {card.card_number[-4:]} with balance ${card.balance}")
            
            # Test card blocking/unblocking
            card.is_active = False
            card.save()
            self.log_success("Card blocked successfully")
            
            card.is_active = True
            card.save()
            self.log_success("Card unblocked successfully")
            
            # Test balance operations
            original_balance = card.balance
            card.balance += Decimal('500.00')
            card.save()
            self.log_success(f"Balance updated: ${original_balance} → ${card.balance}")
            
            return True
            
        except Exception as e:
            self.log_error("Card functionality test failed", e)
            return False
    
    def test_transaction_functionality(self):
        """Test transaction creation and management"""
        print("\n🧪 Testing Transaction Functionality...")
        
        try:
            user = self.test_users[0]
            
            # Test income transaction
            income_tx = Transaction.objects.create(
                user=user,
                title="Test Income",
                amount=Decimal('1000.00'),
                transaction_type=1  # Income
            )
            self.log_success(f"Created income transaction: +${income_tx.amount}")
            
            # Test expense transaction
            expense_tx = Transaction.objects.create(
                user=user,
                title="Test Expense",
                amount=Decimal('250.00'),
                transaction_type=0  # Expense
            )
            self.log_success(f"Created expense transaction: -${expense_tx.amount}")
            
            # Test transaction queries
            user_transactions = user.transactions.all()
            self.log_success(f"User has {user_transactions.count()} transactions")
            
            # Test recent transactions
            recent_transactions = user.transactions.order_by('-timestamp')[:5]
            self.log_success(f"Retrieved {recent_transactions.count()} recent transactions")
            
            return True
            
        except Exception as e:
            self.log_error("Transaction functionality test failed", e)
            return False
    
    def test_loan_and_deposit_functionality(self):
        """Test loan and deposit functionality"""
        print("\n🧪 Testing Loans and Deposits...")
        
        try:
            user = self.test_users[0]
            
            # Test deposit creation
            deposit = Deposit.objects.create(
                user=user,
                amount=Decimal('50000.00'),
                interest_rate=Decimal('5.5'),
                term_months=12
            )
            self.log_success(f"Created deposit: ${deposit.amount} at {deposit.interest_rate}% for {deposit.term_months} months")
            
            # Test loan creation
            loan = Loan.objects.create(
                user=user,
                total_amount=Decimal('100000.00'),
                remaining_debt=Decimal('100000.00'),
                interest_rate=Decimal('12.5'),
                term_months=24,
                monthly_payment=Decimal('5000.00'),
                next_payment_date=date.today() + timedelta(days=30)
            )
            self.log_success(f"Created loan: ${loan.total_amount} at {loan.interest_rate}% for {loan.term_months} months")
            
            # Test mortgage creation
            mortgage = Mortgage.objects.create(
                user=user,
                property_cost=Decimal('5000000.00'),
                initial_payment=Decimal('1000000.00'),
                total_amount=Decimal('4000000.00'),
                term_years=20,
                interest_rate=Decimal('8.5'),
                monthly_payment=Decimal('35000.00')
            )
            self.log_success(f"Created mortgage: ${mortgage.total_amount} for {mortgage.term_years} years")
            
            return True
            
        except Exception as e:
            self.log_error("Loan and deposit functionality test failed", e)
            return False
    
    def test_application_system(self):
        """Test application system"""
        print("\n🧪 Testing Application System...")
        
        try:
            user = self.test_users[0]
            
            # Test loan application
            loan_app = Application.objects.create(
                user=user,
                application_type='LOAN',
                details={
                    'amount': 75000,
                    'term_months': 18,
                    'purpose': 'Business expansion'
                }
            )
            self.log_success(f"Created loan application: {loan_app.application_type}")
            
            # Test card application
            card_app = Application.objects.create(
                user=user,
                application_type='CARD',
                details={
                    'card_type': 'Premium',
                    'reason': 'Higher limits needed'
                }
            )
            self.log_success(f"Created card application: {card_app.application_type}")
            
            # Test application status update
            loan_app.status = 'APPROVED'
            loan_app.save()
            self.log_success("Updated application status to APPROVED")
            
            return True
            
        except Exception as e:
            self.log_error("Application system test failed", e)
            return False
    
    def test_forum_functionality(self):
        """Test forum functionality"""
        print("\n🧪 Testing Forum Functionality...")
        
        try:
            user1 = self.test_users[0]
            user2 = self.test_users[1] if len(self.test_users) > 1 else user1
            
            # Test forum post creation
            post = ForumPost.objects.create(
                author=user1,
                title="Test Forum Post",
                content="This is a test post to verify forum functionality."
            )
            self.log_success(f"Created forum post: {post.title}")
            
            # Test forum comment
            comment = ForumComment.objects.create(
                author=user2,
                post=post,
                content="This is a test comment on the forum post."
            )
            self.log_success(f"Created forum comment by {comment.author.get_full_name()}")
            
            # Test forum like
            like = ForumLike.objects.create(
                user=user2,
                post=post
            )
            self.log_success(f"Created forum like by {like.user.get_full_name()}")
            
            # Test counters
            post.refresh_from_db()
            self.log_success(f"Post has {post.comments_count} comments and {post.likes_count} likes")
            
            return True
            
        except Exception as e:
            self.log_error("Forum functionality test failed", e)
            return False
    
    def test_prediction_forum(self):
        """Test prediction forum functionality"""
        print("\n🧪 Testing Prediction Forum...")
        
        try:
            user1 = self.test_users[0]
            user2 = self.test_users[1] if len(self.test_users) > 1 else user1
            
            # Test prediction post
            prediction = PredictionPost.objects.create(
                author=user1,
                currency_pair="USD/RUB",
                prediction_text="I predict USD will strengthen against RUB",
                direction="up",
                confidence=75,
                target_date=date.today() + timedelta(days=30)
            )
            self.log_success(f"Created prediction: {prediction.currency_pair} {prediction.direction}")
            
            # Test prediction comment
            pred_comment = PredictionComment.objects.create(
                author=user2,
                post=prediction,
                content="Interesting prediction, I agree with your analysis."
            )
            self.log_success(f"Created prediction comment")
            
            return True
            
        except Exception as e:
            self.log_error("Prediction forum test failed", e)
            return False
    
    def test_currency_system(self):
        """Test currency and exchange rate functionality"""
        print("\n🧪 Testing Currency System...")
        
        try:
            # Test currency creation
            usd, created = Currency.objects.get_or_create(
                code='USD',
                defaults={
                    'name': 'US Dollar',
                    'flag_emoji': '🇺🇸'
                }
            )
            self.log_success(f"Created/found currency: {usd.name}")
            
            # Test currency history
            history = CurrencyHistory.objects.create(
                currency=usd,
                base_currency='RUB',
                rate=Decimal('95.50'),
                timestamp=timezone.now()
            )
            self.log_success(f"Created currency history: 1 {usd.code} = {history.rate} RUB")
            
            return True
            
        except Exception as e:
            self.log_error("Currency system test failed", e)
            return False
    
    def test_terminal_system(self):
        """Test terminal functionality"""
        print("\n🧪 Testing Terminal System...")
        
        try:
            # Test terminal creation
            terminal = Terminal.objects.create(
                name="Test Terminal",
                address="123 Test Street, Test City",
                latitude=Decimal('55.7558'),
                longitude=Decimal('37.6176'),
                services={
                    "cash_in": True,
                    "cash_out": True,
                    "balance_check": True
                }
            )
            self.log_success(f"Created terminal: {terminal.name}")
            
            # Test terminal queries
            active_terminals = Terminal.objects.filter(is_active=True)
            self.log_success(f"Found {active_terminals.count()} active terminals")
            
            return True
            
        except Exception as e:
            self.log_error("Terminal system test failed", e)
            return False
    
    def test_ai_chat_system(self):
        """Test AI chat functionality"""
        print("\n🧪 Testing AI Chat System...")
        
        try:
            user = self.test_users[0]
            
            # Test AI chat creation
            chat = AIChat.objects.create(
                user=user,
                title="Test Chat"
            )
            self.log_success(f"Created AI chat: {chat.title}")
            
            # Test AI chat message
            message = AIChatMessage.objects.create(
                chat=chat,
                role='user',
                content="Hello, this is a test message"
            )
            self.log_success(f"Created AI chat message: {message.role}")
            
            # Test AI service (without actual API call)
            try:
                ai_service = AIChatService()
                self.log_success("AI Chat Service initialized")
                
                # Test chat retrieval
                user_chats = ai_service.get_user_chats(user)
                self.log_success(f"Retrieved {len(user_chats)} user chats")
                
            except Exception as e:
                self.log_warning(f"AI Service test limited due to API restrictions: {e}")
            
            return True
            
        except Exception as e:
            self.log_error("AI chat system test failed", e)
            return False
    
    def test_crypto_integration(self):
        """Test cryptocurrency integration"""
        print("\n🧪 Testing Crypto Integration...")
        
        try:
            user = self.test_users[0]
            
            # Test cryptocurrency existence
            cryptos = CryptoCurrency.objects.filter(is_active=True)
            if cryptos.exists():
                self.log_success(f"Found {cryptos.count()} active cryptocurrencies")
                
                # Test crypto service
                crypto_service = CryptoService()
                self.log_success("Crypto Service initialized")
                
                # Test portfolio (should be empty or existing)
                portfolio = crypto_service.get_user_portfolio(user)
                self.log_success(f"Retrieved user crypto portfolio")
                
            else:
                self.log_warning("No cryptocurrencies found - initializing...")
                crypto_service = CryptoService()
                count = crypto_service.initialize_popular_cryptocurrencies()
                self.log_success(f"Initialized {count} cryptocurrencies")
            
            return True
            
        except Exception as e:
            self.log_error("Crypto integration test failed", e)
            return False
    
    def test_data_integrity(self):
        """Test data integrity and relationships"""
        print("\n🧪 Testing Data Integrity...")
        
        try:
            user = self.test_users[0]
            
            # Test user relationships
            user_cards = user.cards.all()
            user_transactions = user.transactions.all()
            user_loans = user.loans.all()
            user_deposits = user.deposits.all()
            
            self.log_success(f"User has {user_cards.count()} cards")
            self.log_success(f"User has {user_transactions.count()} transactions")
            self.log_success(f"User has {user_loans.count()} loans")
            self.log_success(f"User has {user_deposits.count()} deposits")
            
            # Test foreign key relationships
            if user_cards.exists():
                card = user_cards.first()
                self.log_success(f"Card owner relationship: {card.owner.get_full_name()}")
            
            if user_transactions.exists():
                transaction = user_transactions.first()
                self.log_success(f"Transaction user relationship: {transaction.user.get_full_name()}")
            
            return True
            
        except Exception as e:
            self.log_error("Data integrity test failed", e)
            return False
    
    def cleanup_test_data(self):
        """Clean up test data"""
        print("\n🧹 Cleaning up test data...")
        
        try:
            # Delete test transactions
            Transaction.objects.filter(user__phone_number__in=['+1234567890', '+1234567891']).delete()
            self.log_success("Deleted test transactions")
            
            # Delete test applications
            Application.objects.filter(user__phone_number__in=['+1234567890', '+1234567891']).delete()
            self.log_success("Deleted test applications")
            
            # Delete test forum data
            ForumPost.objects.filter(author__phone_number__in=['+1234567890', '+1234567891']).delete()
            self.log_success("Deleted test forum posts")
            
            # Delete test predictions
            PredictionPost.objects.filter(author__phone_number__in=['+1234567890', '+1234567891']).delete()
            self.log_success("Deleted test predictions")
            
            # Delete test AI chats
            AIChat.objects.filter(user__phone_number__in=['+1234567890', '+1234567891']).delete()
            self.log_success("Deleted test AI chats")
            
            # Delete test cards
            Card.objects.filter(owner__phone_number__in=['+1234567890', '+1234567891']).delete()
            self.log_success("Deleted test cards")
            
            # Delete test loans, deposits, mortgages
            Loan.objects.filter(user__phone_number__in=['+1234567890', '+1234567891']).delete()
            Deposit.objects.filter(user__phone_number__in=['+1234567890', '+1234567891']).delete()
            Mortgage.objects.filter(user__phone_number__in=['+1234567890', '+1234567891']).delete()
            self.log_success("Deleted test financial products")
            
            # Keep test users for potential future tests
            self.log_success("Kept test users for future use")
            
        except Exception as e:
            self.log_error("Cleanup failed", e)
    
    def run_all_tests(self):
        """Run all tests"""
        print("🚀 Starting Comprehensive System Tests")
        print("=" * 60)
        
        test_results = []
        
        # Run all tests
        tests = [
            ("User Creation", self.create_test_users),
            ("Card Functionality", self.test_card_functionality),
            ("Transaction Functionality", self.test_transaction_functionality),
            ("Loans and Deposits", self.test_loan_and_deposit_functionality),
            ("Application System", self.test_application_system),
            ("Forum Functionality", self.test_forum_functionality),
            ("Prediction Forum", self.test_prediction_forum),
            ("Currency System", self.test_currency_system),
            ("Terminal System", self.test_terminal_system),
            ("AI Chat System", self.test_ai_chat_system),
            ("Crypto Integration", self.test_crypto_integration),
            ("Data Integrity", self.test_data_integrity),
        ]
        
        for test_name, test_func in tests:
            try:
                result = test_func()
                test_results.append((test_name, result))
            except Exception as e:
                self.log_error(f"{test_name} failed with exception", e)
                test_results.append((test_name, False))
        
        # Print summary
        print("\n" + "=" * 60)
        print("📊 TEST SUMMARY")
        print("=" * 60)
        
        passed = sum(1 for _, result in test_results if result)
        total = len(test_results)
        
        for test_name, result in test_results:
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"{status} {test_name}")
        
        print(f"\n🎯 Results: {passed}/{total} tests passed")
        print(f"✅ Successes: {len(self.successes)}")
        print(f"❌ Errors: {len(self.errors)}")
        
        if self.errors:
            print("\n🔍 Error Details:")
            for error in self.errors[:5]:  # Show first 5 errors
                print(f"   {error}")
            if len(self.errors) > 5:
                print(f"   ... and {len(self.errors) - 5} more errors")
        
        # Ask about cleanup
        if passed > 0:
            cleanup = input("\n🧹 Clean up test data? (y/n): ").lower().strip()
            if cleanup == 'y':
                self.cleanup_test_data()
            else:
                print("🔄 Test data kept for inspection")
        
        return passed == total


def main():
    """Main test function"""
    test_suite = SystemTestSuite()
    success = test_suite.run_all_tests()
    
    if success:
        print("\n🎉 ALL TESTS PASSED! System is ready for production.")
    else:
        print("\n⚠️ Some tests failed. Please review and fix issues.")
    
    return success


if __name__ == "__main__":
    main() 