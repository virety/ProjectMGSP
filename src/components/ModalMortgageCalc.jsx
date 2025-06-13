import React, { useState, useEffect } from "react";
import { RATES } from "../constants/rates";
import "./ModalMortgageCalc.css";
import { FaTimes } from "react-icons/fa";

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

  // Обработчик изменения стоимости недвижимости
  const handlePropertyCostChange = (newValue) => {
    const newPropertyCost = Number(newValue);
    setPropertyCost(newPropertyCost);
    // Автоматически устанавливаем первоначальный взнос в 20% от новой стоимости
    setInitialPayment(Math.round(newPropertyCost * 0.2));
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

  const formatAmount = (value) => {
    return new Intl.NumberFormat('ru-RU', {
      style: 'currency',
      currency: 'RUB',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(value);
  };

  const getDownPaymentPercentage = () => {
    return (initialPayment / propertyCost) * 100;
  };

  if (showSuccess) {
    return (
      <div className="modal-mortgagecalc-overlay">
        <div className="modal-mortgagecalc">
          <button className="modal-mortgagecalc-close" onClick={onClose}><FaTimes /></button>
          <div className="modal-mortgagecalc-title">Заявка принята!</div>
          <p className="modal-mortgagecalc-success-text">
            Ваша заявка на ипотеку принята в обработку.<br />
            Стоимость недвижимости: {formatAmount(propertyCost)}<br />
            Первоначальный взнос: {formatAmount(initialPayment)}<br />
            Срок: {term} {getYearText(term)}<br />
            Ежемесячный платеж: {formatAmount(monthlyPayment)}
          </p>
          <button className="modal-mortgagecalc-submit" onClick={onClose}>
            Закрыть
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="modal-mortgagecalc-overlay">
      <div className="modal-mortgagecalc">
        <button className="modal-mortgagecalc-close" onClick={onClose}><FaTimes /></button>
        <div className="modal-mortgagecalc-title">Рассчитать ипотеку</div>
        <form className="modal-mortgagecalc-form">
          <div className="modal-mortgagecalc-field">
            <label className="modal-mortgagecalc-label">Стоимость недвижимости</label>
            <input
              type="number"
              value={propertyCost}
              onChange={(e) => handlePropertyCostChange(e.target.value)}
              min="1000000"
              step="100000"
              className="modal-mortgagecalc-input"
            />
            <input
              type="range"
              value={propertyCost}
              onChange={(e) => handlePropertyCostChange(e.target.value)}
              min="1000000"
              max="30000000"
              step="100000"
              className="modal-mortgagecalc-slider"
            />
            <div className="modal-mortgagecalc-range">
              <span>1 000 000 ₽</span>
              <span>30 000 000 ₽</span>
            </div>
          </div>

          <div className="modal-mortgagecalc-field">
            <label className="modal-mortgagecalc-label">Первоначальный взнос</label>
            <input
              type="number"
              value={initialPayment}
              onChange={(e) => setInitialPayment(Number(e.target.value))}
              min={0}
              max={propertyCost}
              step="50000"
              className="modal-mortgagecalc-input"
            />
            <div className={`modal-mortgagecalc-percent ${getDownPaymentPercentage() < 20 ? 'error' : ''}`}>
              {getDownPaymentPercentage().toFixed(1)}% от стоимости
              {getDownPaymentPercentage() < 20 && (
                <div className="modal-mortgagecalc-error-text">
                  Минимальный первоначальный взнос - 20%
                </div>
              )}
            </div>
          </div>

          <div className="modal-mortgagecalc-field">
            <label className="modal-mortgagecalc-label">Срок ипотеки: {term} {getYearText(term)}</label>
            <input
              type="range"
              min="1"
              max="30"
              value={term}
              onChange={(e) => setTerm(Number(e.target.value))}
              className="modal-mortgagecalc-slider"
            />
          </div>

          <div className="modal-mortgagecalc-rate">
            Процентная ставка: {rate}% годовых
          </div>

          <div className="modal-mortgagecalc-result">
            <div className="modal-mortgagecalc-total">
              Сумма кредита: {formatAmount(propertyCost - initialPayment)}
            </div>
            <div className="modal-mortgagecalc-payment">
              Ежемесячный платеж: {formatAmount(monthlyPayment)}
            </div>
          </div>

          <button 
            type="button"
            className="modal-mortgagecalc-submit"
            onClick={() => setShowSuccess(true)}
            disabled={!!error || getDownPaymentPercentage() < 20}
          >
            Оформить ипотеку
          </button>
        </form>
      </div>
    </div>
  );
};

export default ModalMortgageCalc;