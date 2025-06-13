#!/usr/bin/env python
"""
API Endpoints test suite for Nyota Bank
Tests all API endpoints to ensure they work correctly
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
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token
from api.models import Card, Transaction

User = get_user_model()

class APIEndpointTests:
    """Test suite for API endpoints"""
    
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
        """Create test user and authentication"""
        print("\n🧪 Setting up test user and authentication...")
        
        try:
            # Create test user
            self.test_user, created = User.objects.get_or_create(
                phone_number='+1234567892',
                defaults={
                    'first_name': 'API',
                    'last_name': 'Tester',
                    'email': 'api@example.com'
                }
            )
            if created:
                self.test_user.set_password('testpass123')
                self.test_user.save()
            
            # Create authentication token
            self.test_token, created = Token.objects.get_or_create(user=self.test_user)
            
            # Set authentication header
            self.client.credentials(HTTP_AUTHORIZATION='Token ' + self.test_token.key)
            
            self.log_success(f"Setup test user: {self.test_user.get_full_name()}")
            self.log_success(f"Created authentication token")
            
            return True
            
        except Exception as e:
            self.log_error("Failed to setup test user", e)
            return False
    
    def test_authentication_endpoints(self):
        """Test authentication related endpoints"""
        print("\n🧪 Testing Authentication Endpoints...")
        
        try:
            # Test login endpoint
            login_data = {
                'phone_number': self.test_user.phone_number,
                'password': 'testpass123'
            }
            
            response = self.client.post('/api/login/', login_data)
            if response.status_code == 200:
                self.log_success("User login endpoint works")
                return True
            else:
                self.log_error(f"Login failed with status {response.status_code}")
                return False
            
        except Exception as e:
            self.log_error("Authentication endpoints test failed", e)
            return False
    
    def test_user_endpoints(self):
        """Test user-related endpoints"""
        print("\n🧪 Testing User Endpoints...")
        
        try:
            # Test user profile endpoint
            response = self.client.get('/api/user/')
            if response.status_code == 200:
                self.log_success("User profile endpoint works")
                data = response.json()
                if 'phone_number' in data:
                    self.log_success("Profile data contains phone_number")
                return True
            else:
                self.log_error(f"Profile endpoint failed with status {response.status_code}")
                return False
            
        except Exception as e:
            self.log_error("User endpoints test failed", e)
            return False
    
    def test_card_endpoints(self):
        """Test card-related endpoints"""
        print("\n🧪 Testing Card Endpoints...")
        
        try:
            # Create a test card first
            test_card = Card.objects.create(
                owner=self.test_user,
                card_name="API Test Card",
                card_number=Card.generate_card_number(),
                balance=Decimal('5000.00'),
                card_expiry_date=Card.generate_expiration_date(),
                cvv=Card.generate_cvv(),
                is_default=True
            )
            
            # Test cards list endpoint
            response = self.client.get('/api/cards/')
            if response.status_code == 200:
                self.log_success("Cards list endpoint works")
                data = response.json()
                if isinstance(data, list) and len(data) > 0:
                    self.log_success(f"Retrieved {len(data)} cards")
                return True
            else:
                self.log_error(f"Cards list failed with status {response.status_code}")
                return False
            
        except Exception as e:
            self.log_error("Card endpoints test failed", e)
            return False
    
    def test_transaction_endpoints(self):
        """Test transaction-related endpoints"""
        print("\n🧪 Testing Transaction Endpoints...")
        
        try:
            # Create test transactions
            Transaction.objects.create(
                user=self.test_user,
                title="API Test Income",
                amount=Decimal('1000.00'),
                transaction_type=1
            )
            
            # Test transactions list endpoint
            response = self.client.get('/api/transactions/')
            if response.status_code == 200:
                self.log_success("Transactions list endpoint works")
                data = response.json()
                if isinstance(data, list):
                    self.log_success(f"Retrieved {len(data)} transactions")
                return True
            else:
                self.log_error(f"Transactions list failed with status {response.status_code}")
                return False
            
        except Exception as e:
            self.log_error("Transaction endpoints test failed", e)
            return False
    
    def test_forum_endpoints(self):
        """Test forum-related endpoints"""
        print("\n🧪 Testing Forum Endpoints...")
        
        try:
            # Test forum posts list
            response = self.client.get('/api/forum/posts/')
            if response.status_code == 200:
                self.log_success("Forum posts list endpoint works")
                return True
            else:
                self.log_error(f"Forum posts list failed with status {response.status_code}")
                return False
            
        except Exception as e:
            self.log_error("Forum endpoints test failed", e)
            return False
    
    def test_currency_endpoints(self):
        """Test currency-related endpoints"""
        print("\n🧪 Testing Currency Endpoints...")
        
        try:
            # Test currencies list
            response = self.client.get('/api/currencies/')
            if response.status_code == 200:
                self.log_success("Currencies list endpoint works")
                data = response.json()
                if isinstance(data, list):
                    self.log_success(f"Retrieved {len(data)} currencies")
                return True
            else:
                self.log_error(f"Currencies list failed with status {response.status_code}")
                return False
            
        except Exception as e:
            self.log_error("Currency endpoints test failed", e)
            return False
    
    def cleanup_test_data(self):
        """Clean up test data"""
        print("\n🧹 Cleaning up API test data...")
        
        try:
            # Delete test user data
            if self.test_user:
                self.test_user.cards.all().delete()
                self.test_user.transactions.all().delete()
                self.log_success("Deleted test user data")
            
            # Delete test users
            User.objects.filter(phone_number='+1234567892').delete()
            self.log_success("Deleted test users")
            
        except Exception as e:
            self.log_error("API cleanup failed", e)
    
    def run_all_tests(self):
        """Run all API tests"""
        print("🚀 Starting API Endpoints Tests")
        print("=" * 60)
        
        # Setup
        if not self.setup_test_user():
            print("❌ Failed to setup test user, aborting tests")
            return False
        
        test_results = []
        
        # Run all tests
        tests = [
            ("Authentication Endpoints", self.test_authentication_endpoints),
            ("User Endpoints", self.test_user_endpoints),
            ("Card Endpoints", self.test_card_endpoints),
            ("Transaction Endpoints", self.test_transaction_endpoints),
            ("Forum Endpoints", self.test_forum_endpoints),
            ("Currency Endpoints", self.test_currency_endpoints),
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
        print("📊 API TESTS SUMMARY")
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
            for error in self.errors[:3]:
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
    test_suite = APIEndpointTests()
    success = test_suite.run_all_tests()
    
    if success:
        print("\n🎉 ALL API TESTS PASSED! Endpoints are working correctly.")
    else:
        print("\n⚠️ Some API tests failed. Please review and fix issues.")
    
    return success


if __name__ == "__main__":
    main() 