#!/usr/bin/env python
import os
import sys
import django
from datetime import datetime, timedelta
import random

# Добавляем путь к Django проекту
sys.path.append('/opt/render/project/src/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nyota_bank.settings')

# Настройка Django
django.setup()

from api.models import Currency, CurrencyHistory
from django.utils import timezone

def create_historical_data():
    """Создает исторические данные для валют за последние 7 дней"""
    
    # Базовые курсы валют
    base_rates = {
        'USD': 78.49,
        'EUR': 90.25,
        'CNY': 10.92,
        'GBP': 105.50,
        'JPY': 0.54,
        'KZT': 0.15
    }
    
    print("Создание исторических данных курсов валют...")
    
    # Получаем все валюты кроме RUB
    currencies = Currency.objects.exclude(code='RUB')
    
    # Создаем данные за последние 7 дней
    now = timezone.now()
    
    for i in range(7):
        # Дата для каждого дня (от 7 дней назад до сегодня)
        date = now - timedelta(days=6-i)
        
        for currency in currencies:
            base_rate = base_rates.get(currency.code, 50.0)
            
            # Создаем несколько записей в день (каждые 4 часа)
            for hour in [0, 4, 8, 12, 16, 20]:
                timestamp = date.replace(hour=hour, minute=0, second=0, microsecond=0)
                
                # Добавляем случайные колебания к курсу (±2% от базового курса)
                variation = random.uniform(-0.02, 0.02)
                rate = base_rate * (1 + variation)
                
                # Проверяем, существует ли уже запись на это время
                existing = CurrencyHistory.objects.filter(
                    currency=currency,
                    timestamp=timestamp
                ).first()
                
                if not existing:
                    CurrencyHistory.objects.create(
                        currency=currency,
                        rate=round(rate, 10),
                        timestamp=timestamp
                    )
                    print(f"Создана запись: {currency.code} - {rate:.4f} на {timestamp}")
    
    print("Исторические данные успешно созданы!")

if __name__ == '__main__':
    create_historical_data() 