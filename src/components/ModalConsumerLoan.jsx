import React, { useState, useEffect } from 'react';
import { RATES } from '../constants/rates';
import './ModalConsumerLoan.css';

const ModalConsumerLoan = ({ onClose }) => {
  const [amount, setAmount] = useState(100000);
  const [term, setTerm] = useState(12);
  const [monthlyPayment, setMonthlyPayment] = useState(0);
  const [showSuccess, setShowSuccess] = useState(false);

  useEffect(() => {
    const calculateMonthlyPayment = () => {
      const monthlyRate = RATES.CONSUMER_LOAN / 12 / 100;
      const payment = amount * (monthlyRate * Math.pow(1 + monthlyRate, term)) / (Math.pow(1 + monthlyRate, term) - 1);
      setMonthlyPayment(Math.round(payment));
    };

    calculateMonthlyPayment();
  }, [amount, term]);

  const handleSubmit = (e) => {
    e.preventDefault();
    setShowSuccess(true);
  };

  const formatCurrency = (value) => {
    return new Intl.NumberFormat('ru-RU').format(value);
  };

  const handleOverlayClick = (e) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  const handleContentClick = (e) => {
    e.stopPropagation();
  };

  if (showSuccess) {
    return (
      <div className="modal-consumer-loan" onClick={handleOverlayClick}>
        <div className="modal-consumer-loan-content" onClick={handleContentClick}>
          <h2>Заявка принята!</h2>
          <p>Мы рассмотрим вашу заявку и свяжемся с вами в ближайшее время.</p>
          <button className="modal-consumer-loan-submit" onClick={onClose}>
            Закрыть
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="modal-consumer-loan" onClick={handleOverlayClick}>
      <div className="modal-consumer-loan-content" onClick={handleContentClick}>
        <h2>Расчет потребительского кредита</h2>
        <form onSubmit={handleSubmit}>
          <div className="modal-consumer-loan-form">
            <div className="modal-consumer-loan-field">
              <label>Сумма кредита</label>
              <div className="modal-consumer-loan-input-group">
                <input
                  type="number"
                  value={amount}
                  onChange={(e) => setAmount(Number(e.target.value))}
                  min="10000"
                  max="5000000"
                  step="10000"

                />
                <span className="modal-consumer-loan-currency">₽</span>
              </div>
              <input
                type="range"
                value={amount}
                onChange={(e) => setAmount(Number(e.target.value))}
                min="10000"
                max="5000000"
                step="10000"
                className="modal-consumer-loan-slider"
              />
              <div className="modal-consumer-loan-range">
                <span>10 000 ₽</span>
                <span>5 000 000 ₽</span>
              </div>
            </div>

            <div className="modal-consumer-loan-field">
              <label>Срок кредита</label>
              <div className="modal-consumer-loan-input-group">
                <input
                  type="number"
                  value={term}
                  onChange={(e) => setTerm(Number(e.target.value))}
                  min="3"
                  max="60"
                  step="3"
                />
                <span className="modal-consumer-loan-currency">мес.</span>
              </div>
              <input
                type="range"
                value={term}
                onChange={(e) => setTerm(Number(e.target.value))}
                min="3"
                max="60"
                step="3"
                className="modal-consumer-loan-slider"
              />
              <div className="modal-consumer-loan-range">
                <span>3 мес.</span>
                <span>60 мес.</span>
              </div>
            </div>

            <div className="modal-consumer-loan-rate">
              <span>Ставка:</span>
              <span className="modal-consumer-loan-rate-value">{RATES.CONSUMER_LOAN}%</span>
            </div>

            <div className="modal-consumer-loan-result">
              <div className="modal-consumer-loan-result-item">
                <span>Ежемесячный платеж:</span>
                <span className="modal-consumer-loan-result-value">{formatCurrency(monthlyPayment)} ₽</span>
              </div>
            </div>

            <button type="submit" className="modal-consumer-loan-submit">
              Оформить кредит
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ModalConsumerLoan;
