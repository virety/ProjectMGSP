from django.core.management.base import BaseCommand
from api.services.currency_service import CurrencyAPIService

class Command(BaseCommand):
    help = 'Fetches latest currency exchange rates and stores them in the database.'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Starting currency rate update...'))
        try:
            CurrencyAPIService.update_currency_history()
            self.stdout.write(self.style.SUCCESS('Successfully updated currency rates.'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'An error occurred: {e}')) 