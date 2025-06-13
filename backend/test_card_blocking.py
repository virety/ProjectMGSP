import os
import django
import requests
import json

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nyota_bank.settings')
django.setup()

from api.models import User, Card
from decimal import Decimal

BASE_URL = "http://localhost:8000/api"

def setup_test_users():
    """Create test users with cards"""
    print("Setting up test users...")
    
    # User 1
    user1, _ = User.objects.get_or_create(
        phone_number='79991234567',
        defaults={'first_name': 'Test', 'last_name': 'UserOne'}
    )
    user1.set_password('password123')
    user1.save()

    card1, _ = Card.objects.get_or_create(
        owner=user1,
        defaults={
            'card_number': Card.generate_card_number(),
            'balance': Decimal('1000.00'),
            'card_expiry_date': Card.generate_expiration_date(),
            'cvv': Card.generate_cvv(),
            'is_active': True
        }
    )
    
    # User 2
    user2, _ = User.objects.get_or_create(
        phone_number='79991234568',
        defaults={'first_name': 'Test', 'last_name': 'UserTwo'}
    )
    user2.set_password('password123')
    user2.save()

    card2, _ = Card.objects.get_or_create(
        owner=user2,
        defaults={
            'card_number': Card.generate_card_number(),
            'balance': Decimal('500.00'),
            'card_expiry_date': Card.generate_expiration_date(),
            'cvv': Card.generate_cvv(),
            'is_active': True
        }
    )
    
    return user1, card1, user2, card2

def test_card_blocking():
    """Test the complete card blocking workflow"""
    print("\n=== CARD BLOCKING TEST ===\n")
    
    # Setup
    user1, card1, user2, card2 = setup_test_users()
    print(f"✓ Test users created")
    print(f"  User 1: {user1.phone_number}, Card: {card1.card_number}, Balance: {card1.balance}")
    print(f"  User 2: {user2.phone_number}, Card: {card2.card_number}, Balance: {card2.balance}")
    
    # Step 1: Login as User 1
    print("\n--- Step 1: Login as User 1 ---")
    login_data = {'phone_number': '79991234567', 'password': 'password123'}
    response = requests.post(f"{BASE_URL}/login/", data=login_data)
    
    if response.status_code != 200:
        print(f"❌ Login failed: {response.status_code} - {response.text}")
        return False
    
    token = response.json()['token']
    headers = {'Authorization': f'Token {token}'}
    print(f"✓ Login successful, token: {token[:20]}...")
    
    # Step 2: Get cards list
    print("\n--- Step 2: Get user's cards ---")
    response = requests.get(f"{BASE_URL}/cards/", headers=headers)
    
    if response.status_code != 200:
        print(f"❌ Failed to get cards: {response.status_code} - {response.text}")
        return False
    
    cards = response.json()
    print(f"✓ Found {len(cards)} cards")
    if cards:
        card_id = cards[0]['id']
        print(f"  Using card ID: {card_id}")
    else:
        print("❌ No cards found")
        return False
    
    # Step 3: Test transfer with ACTIVE card
    print("\n--- Step 3: Transfer with active card ---")
    transfer_data = {
        "source_card_id": card_id,
        "target_card_number": card2.card_number,
        "amount": 50.00
    }
    response = requests.post(f"{BASE_URL}/transfers/", headers=headers, json=transfer_data)
    
    if response.status_code in [200, 201]:
        print("✓ Transfer successful with active card")
    else:
        print(f"❌ Transfer failed: {response.status_code} - {response.text}")
        return False
    
    # Step 4: Block the card
    print("\n--- Step 4: Block the card ---")
    response = requests.post(f"{BASE_URL}/cards/{card_id}/block/", headers=headers)
    
    if response.status_code == 200:
        print("✓ Card blocked successfully")
        print(f"  Response: {response.json()}")
    else:
        print(f"❌ Card blocking failed: {response.status_code} - {response.text}")
        return False
    
    # Step 5: Try transfer with BLOCKED card
    print("\n--- Step 5: Try transfer with blocked card ---")
    transfer_data['amount'] = 25.00
    response = requests.post(f"{BASE_URL}/transfers/", headers=headers, json=transfer_data)
    
    if response.status_code == 403:
        print("✓ Transfer correctly blocked!")
        print(f"  Response: {response.json()}")
    else:
        print(f"❌ Transfer should have been blocked but got: {response.status_code} - {response.text}")
        return False
    
    # Step 6: Unblock the card
    print("\n--- Step 6: Unblock the card ---")
    response = requests.post(f"{BASE_URL}/cards/{card_id}/unblock/", headers=headers)
    
    if response.status_code == 200:
        print("✓ Card unblocked successfully")
        print(f"  Response: {response.json()}")
    else:
        print(f"❌ Card unblocking failed: {response.status_code} - {response.text}")
        return False
    
    # Step 7: Test transfer with UNBLOCKED card
    print("\n--- Step 7: Transfer with unblocked card ---")
    transfer_data['amount'] = 10.00
    response = requests.post(f"{BASE_URL}/transfers/", headers=headers, json=transfer_data)
    
    if response.status_code in [200, 201]:
        print("✓ Transfer successful with unblocked card")
    else:
        print(f"❌ Transfer failed after unblocking: {response.status_code} - {response.text}")
        return False
    
    print("\n🎉 ALL TESTS PASSED! Card blocking functionality works correctly!")
    return True

if __name__ == "__main__":
    try:
        test_card_blocking()
    except Exception as e:
        print(f"❌ Test failed with exception: {e}")
        import traceback
        traceback.print_exc() 