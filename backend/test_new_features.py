#!/usr/bin/env python
"""
Test suite for new features: Analytics and Image Upload
Tests the user analytics API and image upload functionality
"""
import os
import sys
import django
from decimal import Decimal
from io import BytesIO
from PIL import Image as PILImage
from datetime import date, timedelta

# Add the backend directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nyota_bank.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token
from django.core.files.uploadedfile import SimpleUploadedFile
from api.models import (
    Card, Transaction, Loan, Deposit, 
    Mortgage, CryptoCurrency, CryptoWallet
)

User = get_user_model()

class NewFeaturesTests:
    """Test suite for new features"""
    
    def __init__(self):
        self.client = APIClient()
        self.test_user = None
        self.test_token = None
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
    
    def setup_test_user(self):
        """Create test user with comprehensive data"""
        print("\n🧪 Setting up test user with financial data...")
        
        try:
            # Create test user
            self.test_user, created = User.objects.get_or_create(
                phone_number='+1234567890',
                defaults={
                    'first_name': 'Analytics',
                    'last_name': 'Tester',
                    'email': 'analytics@example.com'
                }
            )
            if created:
                self.test_user.set_password('testpass123')
                self.test_user.save()
            
            # Clean up existing test data for this user
            Loan.objects.filter(user=self.test_user).delete()
            Deposit.objects.filter(user=self.test_user).delete()
            Mortgage.objects.filter(user=self.test_user).delete()
            Transaction.objects.filter(user=self.test_user, title__in=[
                "Salary Payment", "Grocery Shopping", "Rent Payment"
            ]).delete()
            
            # Create authentication token
            self.test_token, created = Token.objects.get_or_create(user=self.test_user)
            self.client.credentials(HTTP_AUTHORIZATION='Token ' + self.test_token.key)
            
            # Create test cards
            card1 = Card.objects.get_or_create(
                owner=self.test_user,
                card_name="Primary Card",
                defaults={
                    'card_number': Card.generate_card_number(),
                    'balance': Decimal('15000.00'),
                    'card_expiry_date': Card.generate_expiration_date(),
                    'cvv': Card.generate_cvv(),
                    'is_default': True
                }
            )[0]
            
            card2 = Card.objects.get_or_create(
                owner=self.test_user,
                card_name="Secondary Card",
                defaults={
                    'card_number': Card.generate_card_number(),
                    'balance': Decimal('5000.00'),
                    'card_expiry_date': Card.generate_expiration_date(),
                    'cvv': Card.generate_cvv(),
                    'is_blocked': True  # Blocked card for testing
                }
            )[0]
            
            # Create test transactions
            Transaction.objects.create(
                user=self.test_user,
                title="Salary Payment",
                amount=Decimal('50000.00'),
                transaction_type=1  # Income
            )
            
            Transaction.objects.create(
                user=self.test_user,
                title="Grocery Shopping",
                amount=Decimal('2500.00'),
                transaction_type=2  # Expense
            )
            
            Transaction.objects.create(
                user=self.test_user,
                title="Rent Payment",
                amount=Decimal('25000.00'),
                transaction_type=2  # Expense
            )
            
            # Create test loan
            Loan.objects.create(
                user=self.test_user,
                total_amount=Decimal('500000.00'),
                remaining_debt=Decimal('400000.00'),
                interest_rate=Decimal('15.5'),
                term_months=36,
                monthly_payment=Decimal('15000.00'),
                next_payment_date=date.today() + timedelta(days=30)
            )
            
            # Create test deposit
            Deposit.objects.create(
                user=self.test_user,
                amount=Decimal('100000.00'),
                interest_rate=Decimal('8.5'),
                term_months=12
            )
            
            # Create test mortgage
            Mortgage.objects.create(
                user=self.test_user,
                property_cost=Decimal('5000000.00'),
                initial_payment=Decimal('1000000.00'),
                total_amount=Decimal('4000000.00'),
                interest_rate=Decimal('12.0'),
                term_years=25,
                monthly_payment=Decimal('45000.00')
            )
            
            # Create test crypto data
            try:
                btc = CryptoCurrency.objects.get_or_create(
                    symbol='BTC',
                    defaults={
                        'name': 'Bitcoin',
                        'current_price_usd': Decimal('45000.00'),
                        'is_active': True
                    }
                )[0]
                
                CryptoWallet.objects.get_or_create(
                    user=self.test_user,
                    cryptocurrency=btc,
                    defaults={
                        'balance': Decimal('0.5'),
                        'wallet_address': 'test_btc_address_123'
                    }
                )
            except Exception as e:
                self.log_warning(f"Could not create crypto data: {e}")
            
            self.log_success(f"Setup test user: {self.test_user.get_full_name()}")
            self.log_success(f"Created comprehensive financial data")
            
            return True
            
        except Exception as e:
            self.log_error("Failed to setup test user", e)
            return False
    
    def test_user_analytics_api(self):
        """Test the comprehensive user analytics API"""
        print("\n🧪 Testing User Analytics API...")
        
        try:
            response = self.client.get('/api/analytics/')
            
            if response.status_code == 200:
                self.log_success("Analytics API endpoint accessible")
                
                data = response.json()
                
                # Test user info section
                if 'user_info' in data:
                    user_info = data['user_info']
                    if user_info.get('full_name') == self.test_user.get_full_name():
                        self.log_success("User info correctly populated")
                    if user_info.get('phone_number') == self.test_user.phone_number:
                        self.log_success("Phone number correctly included")
                
                # Test cards analytics
                if 'cards' in data:
                    cards = data['cards']
                    if cards.get('total_cards', 0) >= 2:
                        self.log_success(f"Cards analytics: {cards['total_cards']} cards found")
                    if cards.get('blocked_cards', 0) >= 1:
                        self.log_success("Blocked cards correctly counted")
                    if cards.get('total_balance', 0) > 0:
                        self.log_success(f"Total balance: ${cards['total_balance']}")
                
                # Test transactions analytics
                if 'transactions' in data:
                    transactions = data['transactions']
                    if transactions.get('total_transactions', 0) >= 3:
                        self.log_success(f"Transactions analytics: {transactions['total_transactions']} transactions")
                    if transactions.get('total_income', 0) > 0:
                        self.log_success(f"Income tracked: ${transactions['total_income']}")
                    if transactions.get('total_expense', 0) > 0:
                        self.log_success(f"Expenses tracked: ${transactions['total_expense']}")
                
                # Test loans analytics
                if 'loans' in data:
                    loans = data['loans']
                    if loans.get('total_loans', 0) >= 1:
                        self.log_success(f"Loans analytics: {loans['total_loans']} loans")
                    if loans.get('total_borrowed', 0) > 0:
                        self.log_success(f"Total borrowed: ${loans['total_borrowed']}")
                
                # Test deposits analytics
                if 'deposits' in data:
                    deposits = data['deposits']
                    if deposits.get('total_deposits', 0) >= 1:
                        self.log_success(f"Deposits analytics: {deposits['total_deposits']} deposits")
                    if deposits.get('total_deposited', 0) > 0:
                        self.log_success(f"Total deposited: ${deposits['total_deposited']}")
                
                # Test financial health
                if 'financial_health' in data:
                    health = data['financial_health']
                    if 'score' in health and 'level' in health:
                        self.log_success(f"Financial health: {health['score']}/100 ({health['level']})")
                    if 'recommendations' in health and len(health['recommendations']) > 0:
                        self.log_success(f"Recommendations provided: {len(health['recommendations'])}")
                
                return True
            else:
                self.log_error(f"Analytics API failed with status {response.status_code}")
                return False
            
        except Exception as e:
            self.log_error("Analytics API test failed", e)
            return False
    
    def test_profile_image_upload(self):
        """Test profile image upload functionality"""
        print("\n🧪 Testing Profile Image Upload...")
        
        try:
            # Check if test image exists
            test_image_path = 'test_image.jpg'
            if not os.path.exists(test_image_path):
                self.log_error("Test image not found")
                return False
            
            # Test image upload
            with open(test_image_path, 'rb') as img_file:
                response = self.client.post(
                    '/api/profile/image/',
                    {'image': img_file},
                    format='multipart'
                )
            
            if response.status_code == 200:
                self.log_success("Profile image uploaded successfully")
                
                data = response.json()
                if 'image_url' in data:
                    self.log_success("Image URL returned")
                if 'message' in data:
                    self.log_success(f"Upload message: {data['message']}")
                
                # Verify user has profile image
                self.test_user.refresh_from_db()
                if self.test_user.profile_image:
                    self.log_success("Profile image saved to user model")
                
                # Test image deletion
                delete_response = self.client.delete('/api/profile/image/')
                if delete_response.status_code == 200:
                    self.log_success("Profile image deleted successfully")
                
                return True
            else:
                self.log_error(f"Profile image upload failed with status {response.status_code}")
                if hasattr(response, 'json'):
                    self.log_error(f"Error details: {response.json()}")
                return False
            
        except Exception as e:
            self.log_error("Profile image upload test failed", e)
            return False
    
    def test_card_image_upload(self):
        """Test card image upload functionality"""
        print("\n🧪 Testing Card Image Upload...")
        
        try:
            # Get a test card
            test_card = Card.objects.filter(owner=self.test_user).first()
            if not test_card:
                self.log_error("No test card found")
                return False
            
            # Check if test image exists
            test_image_path = 'test_image.jpg'
            if not os.path.exists(test_image_path):
                self.log_error("Test image not found")
                return False
            
            # Test card image upload
            with open(test_image_path, 'rb') as img_file:
                response = self.client.post(
                    f'/api/cards/{test_card.id}/image/',
                    {'image': img_file},
                    format='multipart'
                )
            
            if response.status_code == 200:
                self.log_success("Card image uploaded successfully")
                
                data = response.json()
                if 'image_url' in data:
                    self.log_success("Card image URL returned")
                if 'card_id' in data:
                    self.log_success(f"Card ID confirmed: {data['card_id']}")
                
                # Verify card has image
                test_card.refresh_from_db()
                if test_card.card_image:
                    self.log_success("Card image saved to card model")
                
                # Test image deletion
                delete_response = self.client.delete(f'/api/cards/{test_card.id}/image/')
                if delete_response.status_code == 200:
                    self.log_success("Card image deleted successfully")
                
                return True
            else:
                self.log_error(f"Card image upload failed with status {response.status_code}")
                if hasattr(response, 'json'):
                    self.log_error(f"Error details: {response.json()}")
                return False
            
        except Exception as e:
            self.log_error("Card image upload test failed", e)
            return False
    
    def test_image_validation(self):
        """Test image validation and processing"""
        print("\n🧪 Testing Image Validation...")
        
        try:
            # Test invalid file type
            invalid_file = SimpleUploadedFile(
                "test.txt",
                b"This is not an image",
                content_type="text/plain"
            )
            
            response = self.client.post(
                '/api/profile/image/',
                {'image': invalid_file},
                format='multipart'
            )
            
            if response.status_code == 400:
                self.log_success("Invalid file type correctly rejected")
            
            # Test oversized image (create a large fake image)
            large_image = PILImage.new('RGB', (5000, 5000), color='red')
            large_image_io = BytesIO()
            large_image.save(large_image_io, format='JPEG', quality=100)
            large_image_io.seek(0)
            
            large_file = SimpleUploadedFile(
                "large.jpg",
                large_image_io.getvalue(),
                content_type="image/jpeg"
            )
            
            response = self.client.post(
                '/api/profile/image/',
                {'image': large_file},
                format='multipart'
            )
            
            if response.status_code == 400:
                self.log_success("Oversized image correctly rejected")
            
            # Test valid small image
            small_image = PILImage.new('RGB', (100, 100), color='blue')
            small_image_io = BytesIO()
            small_image.save(small_image_io, format='JPEG')
            small_image_io.seek(0)
            
            small_file = SimpleUploadedFile(
                "small.jpg",
                small_image_io.getvalue(),
                content_type="image/jpeg"
            )
            
            response = self.client.post(
                '/api/profile/image/',
                {'image': small_file},
                format='multipart'
            )
            
            if response.status_code == 200:
                self.log_success("Valid small image accepted")
            
            return True
            
        except Exception as e:
            self.log_error("Image validation test failed", e)
            return False
    
    def test_analytics_performance(self):
        """Test analytics API performance and data accuracy"""
        print("\n🧪 Testing Analytics Performance...")
        
        try:
            import time
            
            # Measure response time
            start_time = time.time()
            response = self.client.get('/api/analytics/')
            end_time = time.time()
            
            response_time = end_time - start_time
            
            if response.status_code == 200:
                self.log_success(f"Analytics API response time: {response_time:.2f} seconds")
                
                if response_time < 2.0:  # Should respond within 2 seconds
                    self.log_success("Analytics API performance acceptable")
                else:
                    self.log_warning("Analytics API response time is slow")
                
                # Test data consistency
                data = response.json()
                
                # Verify calculations
                if 'transactions' in data:
                    trans = data['transactions']
                    calculated_net = trans.get('total_income', 0) - trans.get('total_expense', 0)
                    reported_net = trans.get('net_balance', 0)
                    
                    if abs(calculated_net - reported_net) < 0.01:  # Allow for floating point precision
                        self.log_success("Transaction calculations are accurate")
                    else:
                        self.log_error(f"Transaction calculation mismatch: {calculated_net} vs {reported_net}")
                
                return True
            else:
                self.log_error(f"Analytics API performance test failed: {response.status_code}")
                return False
            
        except Exception as e:
            self.log_error("Analytics performance test failed", e)
            return False
    
    def cleanup_test_data(self):
        """Clean up test data"""
        print("\n🧹 Cleaning up test data...")
        
        try:
            # Delete test user data
            if self.test_user:
                # Delete related data
                self.test_user.cards.all().delete()
                self.test_user.transactions.all().delete()
                LoanApplication.objects.filter(user=self.test_user).delete()
                DepositApplication.objects.filter(user=self.test_user).delete()
                MortgageApplication.objects.filter(user=self.test_user).delete()
                CryptoWallet.objects.filter(user=self.test_user).delete()
                
                self.log_success("Deleted test user data")
            
            # Delete test users
            User.objects.filter(phone_number='+1234567890').delete()
            self.log_success("Deleted test users")
            
        except Exception as e:
            self.log_error("Cleanup failed", e)
    
    def run_all_tests(self):
        """Run all new feature tests"""
        print("🚀 Starting New Features Tests")
        print("=" * 60)
        
        # Setup
        if not self.setup_test_user():
            print("❌ Failed to setup test user, aborting tests")
            return False
        
        test_results = []
        
        # Run all tests
        tests = [
            ("User Analytics API", self.test_user_analytics_api),
            ("Profile Image Upload", self.test_profile_image_upload),
            ("Card Image Upload", self.test_card_image_upload),
            ("Image Validation", self.test_image_validation),
            ("Analytics Performance", self.test_analytics_performance),
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
        print("📊 NEW FEATURES TESTS SUMMARY")
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
        
        # Ask about cleanup
        cleanup = input("\n🧹 Clean up test data? (y/n): ").lower().strip()
        if cleanup == 'y':
            self.cleanup_test_data()
        else:
            print("🔄 Test data kept for inspection")
        
        # Return TRUE only if ALL tests passed
        return passed == total


def main():
    """Main test function"""
    test_suite = NewFeaturesTests()
    success = test_suite.run_all_tests()
    
    if success:
        print("\n🎉 ALL NEW FEATURES TESTS PASSED! Analytics and Image Upload working correctly.")
    else:
        print("\n⚠️ Some new features tests failed. Please review and fix issues.")
    
    return success


if __name__ == "__main__":
    main() 