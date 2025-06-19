from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
import random
from api.models import Currency, CurrencyHistory

class Command(BaseCommand):
    help = 'Create historical currency data for testing'

    def handle(self, *args, **options):
        self.stdout.write('Создание исторических данных курсов валют...')
        
        # Базовые курсы валют
        base_rates = {
            'USD': 78.49,
            'EUR': 90.25,
            'CNY': 10.92,
            'GBP': 105.50,
            'JPY': 0.54,
            'KZT': 0.15
        }
        
        # Получаем все валюты кроме RUB
        currencies = Currency.objects.exclude(code='RUB')
        
        # Создаем данные за последние 7 дней
        now = timezone.now()
        created_count = 0
        
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
                        created_count += 1
                        self.stdout.write(f"✓ {currency.code}: {rate:.4f} на {timestamp.strftime('%Y-%m-%d %H:%M')}")
        
        self.stdout.write(
            self.style.SUCCESS(f'Успешно создано {created_count} исторических записей!')
        ) 