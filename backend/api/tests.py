from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from .models import User, Card, Transaction
from decimal import Decimal

# Create your tests here.

class TransferAPITest(APITestCase):
    def setUp(self):
        """
        Set up the test environment.
        This method is called before each test.
        """
        # Create users
        self.user_alice = User.objects.create_user(
            phone_number='+79991112233', 
            password='password123', 
            first_name='Алиса', 
            last_name='Селезнева',
            email='alice@example.com'
        )
        self.user_bob = User.objects.create_user(
            phone_number='+79994445566', 
            password='password456', 
            first_name='Боб', 
            last_name='Строитель',
            email='bob@example.com'
        )

        # Create cards
        # Alice has two cards, one with money
        self.alice_card_1 = Card.objects.create(
            owner=self.user_alice, 
            card_number='1111000011110000', 
            balance=Decimal('1000.00'),
            card_expiry_date='2030-01-01',
            cvv='123'
        )
        self.alice_card_2 = Card.objects.create(
            owner=self.user_alice, 
            card_number='2222000022220000', 
            balance=Decimal('50.00'),
            card_expiry_date='2030-01-01',
            cvv='123'
        )

        # Bob has one card with no money initially
        self.bob_card_1 = Card.objects.create(
            owner=self.user_bob, 
            card_number='3333000033330000', 
            balance=Decimal('0.00'),
            card_expiry_date='2030-01-01',
            cvv='123'
        )

        # URL for the transfer endpoint
        self.transfer_url = reverse('transfer')

    def test_successful_transfer_by_card_number(self):
        """
        Ensure a user can successfully transfer money to another user's card.
        """
        self.client.force_authenticate(user=self.user_alice)
        data = {
            "sender_card_number": self.alice_card_1.card_number,
            "recipient_identifier": self.bob_card_1.card_number,
            "amount": "150.50"
        }
        response = self.client.post(self.transfer_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        self.alice_card_1.refresh_from_db()
        self.bob_card_1.refresh_from_db()
        
        self.assertEqual(self.alice_card_1.balance, Decimal('849.50'))
        self.assertEqual(self.bob_card_1.balance, Decimal('150.50'))
        self.assertEqual(Transaction.objects.count(), 2)

    def test_successful_transfer_by_phone_number(self):
        """
        Ensure a user can successfully transfer money using a phone number.
        The money should go to the recipient's default (first-created) card.
        """
        self.client.force_authenticate(user=self.user_alice)
        data = {
            "sender_card_number": self.alice_card_1.card_number,
            "recipient_identifier": self.user_bob.phone_number,
            "amount": "100"
        }
        response = self.client.post(self.transfer_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        self.alice_card_1.refresh_from_db()
        self.bob_card_1.refresh_from_db()

        self.assertEqual(self.alice_card_1.balance, Decimal('900.00'))
        self.assertEqual(self.bob_card_1.balance, Decimal('100.00'))
    
    def test_insufficient_funds_transfer(self):
        """
        Ensure the transfer fails if the sender has insufficient funds.
        """
        self.client.force_authenticate(user=self.user_alice)
        data = {
            "sender_card_number": self.alice_card_1.card_number,
            "recipient_identifier": self.bob_card_1.card_number,
            "amount": "2000.00" # More than Alice has
        }
        response = self.client.post(self.transfer_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        # Ensure balances have not changed
        self.alice_card_1.refresh_from_db()
        self.bob_card_1.refresh_from_db()
        self.assertEqual(self.alice_card_1.balance, Decimal('1000.00'))
        self.assertEqual(self.bob_card_1.balance, Decimal('0.00'))

    def test_transfer_to_same_card_fails(self):
        """
        Ensure transfer to the same card is not allowed.
        """
        self.client.force_authenticate(user=self.user_alice)
        data = {
            "sender_card_number": self.alice_card_1.card_number,
            "recipient_identifier": self.alice_card_1.card_number,
            "amount": "10.00"
        }
        response = self.client.post(self.transfer_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_transfer_to_self_by_phone_fails(self):
        """
        Ensure transfer to self by phone number is not allowed.
        """
        self.client.force_authenticate(user=self.user_alice)
        data = {
            "sender_card_number": self.alice_card_1.card_number,
            "recipient_identifier": self.user_alice.phone_number,
            "amount": "10.00"
        }
        response = self.client.post(self.transfer_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_transfer_between_own_cards_succeeds(self):
        """
        Ensure a user can transfer money between their own cards.
        """
        self.client.force_authenticate(user=self.user_alice)
        data = {
            "sender_card_number": self.alice_card_1.card_number,
            "recipient_identifier": self.alice_card_2.card_number,
            "amount": "200.00"
        }
        response = self.client.post(self.transfer_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.alice_card_1.refresh_from_db()
        self.alice_card_2.refresh_from_db()

        self.assertEqual(self.alice_card_1.balance, Decimal('800.00'))
        self.assertEqual(self.alice_card_2.balance, Decimal('250.00'))
