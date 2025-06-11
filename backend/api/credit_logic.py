from django.conf import settings
from django.utils import timezone
from datetime import date, timedelta
from decimal import Decimal
from django.db.models import Sum

# This class replicates the logic from CreditHistoryManager.swift
class CreditLogicManager:
    
    def get_detailed_credit_score(self, user):
        """
        Calculates the credit score and returns a detailed breakdown.
        """
        breakdown = {'base_score': 400}
        score = 400

        # Account age factor
        if user.date_joined:
            account_age_days = (timezone.now().date() - user.date_joined.date()).days
            age_bonus = min(account_age_days // 7, 100)
            score += age_bonus
            breakdown['account_age_bonus'] = age_bonus
            breakdown['account_age_days'] = account_age_days

        # Transaction history factor
        transaction_count = user.transactions.count()
        transaction_bonus = min(transaction_count * 5, 100)
        score += transaction_bonus
        breakdown['transaction_bonus'] = transaction_bonus
        breakdown['transaction_count'] = transaction_count

        # Balance factor
        total_balance = user.cards.aggregate(Sum('balance'))['balance__sum'] or Decimal('0.0')
        balance_bonus = 0
        if total_balance >= 100000:
            balance_bonus = 100
        elif total_balance >= 50000:
            balance_bonus = 50
        elif total_balance >= 10000:
            balance_bonus = 25
        score += balance_bonus
        breakdown['balance_bonus'] = balance_bonus
        breakdown['current_balance'] = float(total_balance)

        # Loan history
        loan_penalty = 0
        loan_bonus = 0
        for loan in user.loans.all():
            if loan.is_active:
                loan_penalty += 20
                if loan.next_payment_date and loan.next_payment_date < timezone.now().date():
                    loan_penalty += 50
            else:
                loan_bonus += 75
        score -= loan_penalty
        score += loan_bonus
        breakdown['loan_penalty'] = loan_penalty
        breakdown['completed_loan_bonus'] = loan_bonus

        # Mortgage history
        for mortgage in user.mortgages.all():
            if mortgage.is_active:
                score += 30
                if hasattr(user, 'card') and user.card.balance > 0:
                    mortgage_to_balance_ratio = mortgage.total_amount / user.card.balance
                    if mortgage_to_balance_ratio <= 3:
                        score += 20
            else:
                score += 150 # Completed mortgage bonus
        
        # Recent transaction frequency
        one_month_ago = timezone.now() - timedelta(days=30)
        recent_transactions_count = user.transactions.filter(timestamp__gte=one_month_ago).count()
        recent_bonus = 25 if recent_transactions_count >= 5 else 0
        score += recent_bonus
        breakdown['recent_activity_bonus'] = recent_bonus
        breakdown['recent_transactions_count'] = recent_transactions_count
        
        final_score = max(0, min(1000, score))
        breakdown['final_score'] = final_score
        return breakdown

    def calculate_credit_score(self, user):
        # This now uses the detailed calculation but returns only the final score
        return self.get_detailed_credit_score(user)['final_score']

    def can_take_credit(self, user):
        return self.calculate_credit_score(user) >= 400

    def get_max_credit_amount(self, user):
        score = self.calculate_credit_score(user)
        
        if 800 <= score <= 1000:
            base_amount = Decimal('1000000')
        elif 600 <= score < 800:
            base_amount = Decimal('500000')
        elif 400 <= score < 600:
            base_amount = Decimal('100000')
        else:
            base_amount = Decimal('0')

        total_balance = user.cards.aggregate(Sum('balance'))['balance__sum'] or Decimal('0.0')
        balance_multiplier = min(total_balance / Decimal('10000'), Decimal('2.0'))
        return base_amount * balance_multiplier

    def get_credit_interest_rate(self, user):
        score = self.calculate_credit_score(user)
        
        if 900 <= score <= 1000:
            return Decimal('8.0')
        if 800 <= score < 900:
            return Decimal('10.0')
        if 700 <= score < 800:
            return Decimal('12.0')
        if 600 <= score < 700:
            return Decimal('14.0')
        if 400 <= score < 600:
            return Decimal('16.0')
        return Decimal('20.0')

    def calculate_monthly_payment(self, principal, annual_rate, term_months):
        if term_months == 0:
            return Decimal('0.0')
        
        monthly_rate = (annual_rate / 100) / 12
        if monthly_rate == 0:
            return principal / Decimal(term_months)
        
        # Annuity payment formula
        numerator = monthly_rate * ((1 + monthly_rate) ** term_months)
        denominator = ((1 + monthly_rate) ** term_months) - 1
        monthly_payment = principal * (numerator / denominator)
        
        return monthly_payment.quantize(Decimal('0.01'))

    # --- Mortgage Logic ---

    def can_take_mortgage(self, user):
        mortgages = user.mortgages.filter(is_active=True).count()
        if mortgages > 0:
            return False  # Already has an active mortgage
        
        return self.calculate_credit_score(user) >= 600

    def get_max_mortgage_amount(self, user):
        score = self.calculate_credit_score(user)
        
        if 900 <= score <= 1000:
            base_multiplier = Decimal('5.0')
        elif 800 <= score < 900:
            base_multiplier = Decimal('4.0')
        elif 700 <= score < 800:
            base_multiplier = Decimal('3.0')
        elif 600 <= score < 700:
            base_multiplier = Decimal('2.0')
        else:
            base_multiplier = Decimal('0.0')

        # Using total balance as a proxy for annual income for simplicity
        total_balance = user.cards.aggregate(Sum('balance'))['balance__sum'] or Decimal('0.0')
        max_amount = total_balance * 12 * base_multiplier # Assuming total balance is a monthly income proxy
        
        return min(max_amount, Decimal('10000000'))

    def get_mortgage_interest_rate(self, user):
        # Starts with the base rate from settings and adjusts based on score
        base_rate = Decimal(str(settings.MORTGAGE_BASE_RATE))
        score = self.calculate_credit_score(user)

        if 900 <= score <= 1000:
            return base_rate - Decimal('2.0') # Discount for excellent score
        if 800 <= score < 900:
            return base_rate - Decimal('1.0') # Slight discount
        if 600 <= score < 700:
            return base_rate + Decimal('1.0') # Higher risk
        
        return base_rate 