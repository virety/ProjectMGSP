from celery import shared_task
from .services.currency_service import CurrencyAPIService

@shared_task
def update_currency_rates_task():
    """
    A Celery task to update currency rates.
    """
    print("Executing update_currency_rates_task...")
    CurrencyAPIService.update_currency_history()
    print("Finished update_currency_rates_task.") 