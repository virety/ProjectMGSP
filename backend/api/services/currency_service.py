import requests
from datetime import datetime
from decimal import Decimal
from django.conf import settings
from django.utils.timezone import make_aware

from api.models import Currency, CurrencyHistory

# The API key is now fetched from Django settings
BASE_URL = "https://v6.exchangerate-api.com/v6"

class CurrencyAPIService:
    def __init__(self, api_key=None):
        self.api_key = api_key or settings.EXCHANGE_RATE_API_KEY

    def fetch_latest_rates(self, base_currency="RUB"):
        """
        Fetches the latest currency exchange rates from the API.
        """
        url = f"{BASE_URL}/{self.api_key}/latest/{base_currency}"
        try:
            response = requests.get(url)
            response.raise_for_status()  # Raises an HTTPError for bad responses (4xx or 5xx)
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching data from ExchangeRate-API: {e}")
            return None

    @staticmethod
    def update_currency_history():
        """
        Fetches the latest rates and updates the CurrencyHistory table.
        This is the main function to be called periodically.
        """
        service = CurrencyAPIService()
        data = service.fetch_latest_rates()

        if not data or data.get("result") != "success":
            print("Failed to fetch valid currency data.")
            return

        # The API returns rates for 1 RUB. We need to find how much 1 unit of foreign currency costs in RUB.
        # So we need to calculate 1 / rate.
        rates = data.get("conversion_rates", {})
        timestamp_utc = datetime.utcfromtimestamp(data.get("time_last_update_unix"))
        aware_timestamp = make_aware(timestamp_utc)

        target_currencies = Currency.objects.exclude(code="RUB").values_list('code', flat=True)

        for currency_code in target_currencies:
            if currency_code in rates:
                try:
                    currency = Currency.objects.get(code=currency_code)
                    # The rate from API is how many `currency_code` you get for 1 RUB.
                    # We want to store how many RUB you need for 1 `currency_code`.
                    rate = Decimal(1.0) / Decimal(rates[currency_code])

                    CurrencyHistory.objects.create(
                        currency=currency,
                        base_currency="RUB",
                        rate=rate,
                        timestamp=aware_timestamp
                    )
                except Currency.DoesNotExist:
                    print(f"Currency with code {currency_code} not found in the database.")
                except Exception as e:
                    print(f"Error processing currency {currency_code}: {e}")
        
        print("Successfully updated currency history.") 