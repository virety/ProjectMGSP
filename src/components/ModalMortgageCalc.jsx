import React, { useState, useEffect } from "react";
import { RATES } from "../constants/rates";
import "./ModalMortgageCalc.css";

const ModalMortgageCalc = ({ show, onClose }) => {
  const [propertyCost, setPropertyCost] = useState(3000000);
  const [initialPayment, setInitialPayment] = useState(600000);
  const [term, setTerm] = useState(20);
  const [monthlyPayment, setMonthlyPayment] = useState(0);
  const [showSuccess, setShowSuccess] = useState(false);
  const [error, setError] = useState('');
  const rate = RATES.MORTGAGE;

  const getYearText = (years) => {
    const lastDigit = years % 10;
    const lastTwoDigits = years % 100;
    
    if (lastTwoDigits >= 11 && lastTwoDigits <= 19) {
      return 'лет';
    }
    
    if (lastDigit === 1) {
      return 'год';
    }
    
    if (lastDigit >= 2 && lastDigit <= 4) {
      return 'года';
    }
    
    return 'лет';
  };

  useEffect(() => {
    const loanAmount = propertyCost - initialPayment;
    if (loanAmount < 500000) {
      setError('Сумма кредита не может быть менее 500 000 рублей');
      return;
    }

    const downPaymentPercent = (initialPayment / propertyCost) * 100;
    if (downPaymentPercent < 20) {
      setError('Первый взнос должен быть не менее 20% от стоимости недвижимости');
      return;
    }

    setError('');
    const monthlyRate = rate / 12 / 100;
    const numberOfPayments = term * 12;
    const payment = loanAmount * (monthlyRate * Math.pow(1 + monthlyRate, numberOfPayments)) / (Math.pow(1 + monthlyRate, numberOfPayments) - 1);
    setMonthlyPayment(Math.round(payment));
  }, [propertyCost, initialPayment, term, rate]);

  if (!show) return null;

  const handleSubmit = () => {
    setShowSuccess(true);
  };

  const formatAmount = (value) => {
    return new Intl.NumberFormat('ru-RU', {
      style: 'currency',
      currency: 'RUB',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(value);
  };

  return (
    <div className="modal-mortgagecalc-overlay" onClick={onClose}>
      <div className="modal-mortgagecalc" onClick={e => e.stopPropagation()}>
        <button className="modal-mortgagecalc-close" onClick={onClose}>×</button>
        
        {!showSuccess ? (
          <>
            <div className="modal-mortgagecalc-title">Ипотечный калькулятор</div>
            <div className="modal-mortgagecalc-form">
              <div className="modal-mortgagecalc-field">
                <label>Стоимость недвижимости</label>
                <div className="modal-mortgagecalc-input-group">
                  <input
                    type="number"
                    value={propertyCost}
                    onChange={(e) => setPropertyCost(Number(e.target.value))}
                    min="500000"
                    step="100000"
                    className="modal-mortgagecalc-input"
                  />
                  <span className="modal-mortgagecalc-currency">₽</span>
                </div>
              </div>

              <div className="modal-mortgagecalc-field">
                <label>Первый взнос</label>
                <div className="modal-mortgagecalc-input-group">
                  <input
                    type="number"
                    value={initialPayment}
                    onChange={(e) => setInitialPayment(Number(e.target.value))}
                    min="0"
                    step="10000"
                    className="modal-mortgagecalc-input"
                  />
                  <span className="modal-mortgagecalc-currency">₽</span>
                </div>
                <div className="modal-mortgagecalc-percent">
                  {((initialPayment / propertyCost) * 100).toFixed(1)}% от стоимости
                </div>
              </div>

              <div className="modal-mortgagecalc-field">
                <label>Срок кредита: {term} {getYearText(term)}</label>
                <input
                  type="range"
                  min="1"
                  max="30"
                  value={term}
                  onChange={(e) => setTerm(Number(e.target.value))}
                  className="modal-mortgagecalc-slider"
                />
                <div className="modal-mortgagecalc-slider-labels">
                  <span>1 год</span>
                  <span>30 лет</span>
                </div>
              </div>

              <div className="modal-mortgagecalc-rate">
                Процентная ставка: {rate}% годовых
              </div>

              {error && <div className="modal-mortgagecalc-error">{error}</div>}

              <div className="modal-mortgagecalc-result">
                <div className="modal-mortgagecalc-loan-amount">
                  Сумма кредита: {formatAmount(propertyCost - initialPayment)}
                </div>
                <div className="modal-mortgagecalc-payment">
                  Ежемесячный платеж: {formatAmount(monthlyPayment)}
                </div>
              </div>

              <button 
                className="modal-mortgagecalc-submit"
                onClick={handleSubmit}
                disabled={!!error}
              >
                Оформить ипотеку
              </button>
            </div>
          </>
        ) : (
          <div className="modal-mortgagecalc-success">
            <h2>Банк скоро примет решение!</h2>
            <p>Ожидайте оповещения</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ModalMortgageCalc;