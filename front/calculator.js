document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.service-card .btn.outline').forEach(btn => {
        btn.addEventListener('click', function() {
            if (this.textContent.includes('Рассчитать')) {
                const modal = document.getElementById('deposit-calculator-modal');
                modal.style.display = 'block';
                document.body.classList.add('modal-open');
                initCalculator();
            }
        });
    });

    function getMonthWord(months) {
        if (months % 100 >= 11 && months % 100 <= 14) {
            return 'месяцев';
        }
        switch(months % 10) {
            case 1: return 'месяц';
            case 2:
            case 3:
            case 4: return 'месяца';
            default: return 'месяцев';
        }
    }

    function initCalculator() {
        const modal = document.getElementById('deposit-calculator-modal');
        const termSlider = document.getElementById('deposit-term');
        const amountSlider = document.getElementById('deposit-amount');
        const checkbox = document.getElementById('non-replenishable');
        const termValue = document.getElementById('term-value');
        const amountValue = document.getElementById('amount-value');
        const rateValue = document.getElementById('interest-rate');
        const totalValue = document.getElementById('total-amount');
        const profitValue = document.getElementById('profit-amount');

        termSlider.style.setProperty('--track-width', '100%');
        amountSlider.style.setProperty('--track-width', '100%');

        function formatNumber(num) {
            return new Intl.NumberFormat('ru-RU').format(num);
        }
        
        function calculate() {
            const months = parseInt(termSlider.value);
            const amount = parseInt(amountSlider.value);
            const rate = checkbox.checked ? 19 : 17;
            
            const profit = Math.round(amount * rate / 100 * months / 12);
            const total = amount + profit;
            
            termValue.textContent = `${months} ${getMonthWord(months)}`;
            amountValue.textContent = `${formatNumber(amount)} ₽`;
            rateValue.textContent = `${rate}%`;
            totalValue.textContent = `${formatNumber(total)} ₽`;
            profitValue.textContent = `+${formatNumber(profit)} ₽`;
        }
        
        termSlider.addEventListener('input', calculate);
        amountSlider.addEventListener('input', calculate);
        checkbox.addEventListener('change', calculate);

        modal.querySelector('.close-modal').addEventListener('click', () => {
            modal.style.display = 'none';
            document.body.classList.remove('modal-open');
        });
        
        window.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.style.display = 'none';
                document.body.classList.remove('modal-open');
            }
        });
        calculate();
    }

});