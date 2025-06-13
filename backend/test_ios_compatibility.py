#!/usr/bin/env python3
"""
Тест совместимости Django Backend с iOS приложением
Проверяет наличие всех необходимых полей для интеграции
"""

import os
import sys
import django
from decimal import Decimal
from datetime import date, timedelta
import random
import time

# Настройка Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nyota_bank.settings')
django.setup()

from api.models import User, Card, Loan, Mortgage, Deposit

class IOSCompatibilityTest:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.test_users = []
        
    def cleanup(self):
        """Очистка тестовых данных"""
        for user in self.test_users:
            try:
                user.delete()
            except:
                pass
        self.test_users = []
        
    def create_test_user(self, suffix=""):
        """Создание тестового пользователя с уникальным номером"""
        timestamp = str(int(time.time() * 1000))[-8:]  # Последние 8 цифр timestamp
        phone = f"+7999{timestamp}{suffix}"
        
        user = User.objects.create_user(
            phone_number=phone,
            password="testpass123",
            first_name="Тест",
            last_name=f"Пользователь{suffix}"
        )
        self.test_users.append(user)
        return user
        
    def log_success(self, message):
        print(f"✅ {message}")
        self.passed += 1
        
    def log_error(self, message):
        print(f"❌ {message}")
        self.failed += 1
        
    def test_user_fields(self):
        """Тест полей User модели для iOS совместимости"""
        print("\n🔍 Тестирование User модели...")
        
        user = self.create_test_user("1")
        
        # Проверяем наличие total_balance поля
        if hasattr(user, 'total_balance'):
            self.log_success("User.total_balance поле существует")
            
            # Проверяем метод update_total_balance
            if hasattr(user, 'update_total_balance'):
                user.update_total_balance()
                self.log_success("User.update_total_balance() метод работает")
            else:
                self.log_error("User.update_total_balance() метод отсутствует")
        else:
            self.log_error("User.total_balance поле отсутствует")
        
    def test_card_fields(self):
        """Тест полей Card модели для iOS совместимости"""
        print("\n🔍 Тестирование Card модели...")
        
        user = self.create_test_user("2")
        
        # Генерируем уникальный номер карты
        card_number = ''.join([str(random.randint(0, 9)) for _ in range(16)])
        
        card = Card.objects.create(
            owner=user,
            card_name="Test Card",
            card_number=card_number,
            balance=Decimal('1000.00'),
            card_expiry_date=date.today() + timedelta(days=365),
            cvv="123",
            gradient_start_hex="#FF6B6B",
            gradient_end_hex="#4ECDC4"
        )
        
        # Проверяем gradient поля
        if hasattr(card, 'gradient_start_hex') and hasattr(card, 'gradient_end_hex'):
            self.log_success("Card gradient поля существуют")
            
            if card.gradient_start_hex == "#FF6B6B" and card.gradient_end_hex == "#4ECDC4":
                self.log_success("Card gradient поля сохраняются корректно")
            else:
                self.log_error("Card gradient поля не сохраняются корректно")
        else:
            self.log_error("Card gradient поля отсутствуют")
        
    def test_loan_fields(self):
        """Тест полей Loan модели для iOS совместимости"""
        print("\n🔍 Тестирование Loan модели...")
        
        user = self.create_test_user("3")
        
        loan = Loan.objects.create(
            user=user,
            total_amount=Decimal('100000.00'),
            remaining_debt=Decimal('90000.00'),
            interest_rate=Decimal('12.5'),
            term_months=24,
            monthly_payment=Decimal('5000.00'),
            next_payment_date=date.today() + timedelta(days=30),
            late_payments=2,
            next_payment_amount=Decimal('5200.00')
        )
        
        # Проверяем новые поля
        required_fields = ['late_payments', 'next_payment_amount']
        for field in required_fields:
            if hasattr(loan, field):
                self.log_success(f"Loan.{field} поле существует")
            else:
                self.log_error(f"Loan.{field} поле отсутствует")
        
    def test_mortgage_fields(self):
        """Тест полей Mortgage модели для iOS совместимости"""
        print("\n🔍 Тестирование Mortgage модели...")
        
        user = self.create_test_user("4")
        
        mortgage = Mortgage.objects.create(
            user=user,
            property_cost=Decimal('5000000.00'),
            initial_payment=Decimal('1000000.00'),
            total_amount=Decimal('4000000.00'),
            term_years=20,
            interest_rate=Decimal('8.5'),
            monthly_payment=Decimal('25000.00'),
            late_payments=1,
            central_bank_rate=Decimal('7.5'),
            overpayment=Decimal('50000.00')
        )
        
        # Проверяем новые поля
        required_fields = ['late_payments', 'central_bank_rate', 'overpayment']
        for field in required_fields:
            if hasattr(mortgage, field):
                self.log_success(f"Mortgage.{field} поле существует")
            else:
                self.log_error(f"Mortgage.{field} поле отсутствует")
        
    def test_deposit_fields(self):
        """Тест полей Deposit модели для iOS совместимости"""
        print("\n🔍 Тестирование Deposit модели...")
        
        user = self.create_test_user("5")
        
        deposit = Deposit.objects.create(
            user=user,
            amount=Decimal('50000.00'),
            interest_rate=Decimal('6.5'),
            term_months=12,
            total_interest=Decimal('3250.00')
        )
        
        # Проверяем новое поле
        if hasattr(deposit, 'total_interest'):
            self.log_success("Deposit.total_interest поле существует")
            
            if deposit.total_interest == Decimal('3250.00'):
                self.log_success("Deposit.total_interest поле сохраняется корректно")
            else:
                self.log_error("Deposit.total_interest поле не сохраняется корректно")
        else:
            self.log_error("Deposit.total_interest поле отсутствует")
        
    def run_all_tests(self):
        """Запуск всех тестов"""
        print("🚀 Запуск тестов совместимости с iOS...")
        
        try:
            self.test_user_fields()
            self.test_card_fields()
            self.test_loan_fields()
            self.test_mortgage_fields()
            self.test_deposit_fields()
        finally:
            self.cleanup()
        
        print(f"\n📊 Результаты тестирования:")
        print(f"✅ Успешно: {self.passed}")
        print(f"❌ Ошибок: {self.failed}")
        print(f"📈 Процент успеха: {(self.passed / (self.passed + self.failed) * 100):.1f}%")
        
        if self.failed == 0:
            print("\n🎉 Все тесты прошли успешно! Backend готов для интеграции с iOS!")
        else:
            print(f"\n⚠️  Обнаружено {self.failed} проблем. Необходимо исправить перед интеграцией с iOS.")

if __name__ == "__main__":
    test = IOSCompatibilityTest()
    test.run_all_tests() 