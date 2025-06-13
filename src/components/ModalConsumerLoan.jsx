import React, { useState, useEffect } from 'react';
import { RATES } from '../constants/rates';
import './ModalConsumerLoan.css';
import { FaTimes } from 'react-icons/fa';

const ModalConsumerLoan = ({ show, onClose }) => {
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

  if (!show) return null;

  if (showSuccess) {
    return (
      <div className="modal-consumerloan-overlay">
        <div className="modal-consumerloan">
          <button className="modal-consumerloan-close" onClick={onClose}><FaTimes /></button>
          <div className="modal-consumerloan-title">Заявка принята!</div>
          <p className="modal-consumerloan-success-text">Мы рассмотрим вашу заявку и свяжемся с вами в ближайшее время.</p>
          <button className="modal-consumerloan-submit" onClick={onClose}>
            Закрыть
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="modal-consumerloan-overlay">
      <div className="modal-consumerloan">
        <button className="modal-consumerloan-close" onClick={onClose}><FaTimes /></button>
        <div className="modal-consumerloan-title">Расчет потребительского кредита</div>
        <form onSubmit={handleSubmit} className="modal-consumerloan-form">
          <div className="modal-consumerloan-field">
            <label className="modal-consumerloan-label">Сумма кредита</label>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(Number(e.target.value))}
              min="10000"
              max="5000000"
              step="10000"
              className="modal-consumerloan-input"
            />
            <input
              type="range"
              value={amount}
              onChange={(e) => setAmount(Number(e.target.value))}
              min="10000"
              max="5000000"
              step="10000"
              className="modal-consumerloan-slider"
            />
            <div className="modal-consumerloan-range">
              <span>10 000 ₽</span>
              <span>5 000 000 ₽</span>
            </div>
          </div>

          <div className="modal-consumerloan-field">
            <label className="modal-consumerloan-label">Срок кредита</label>
            <input
              type="number"
              value={term}
              onChange={(e) => setTerm(Number(e.target.value))}
              min="3"
              max="60"
              step="1"
              className="modal-consumerloan-input"
            />
            <input
              type="range"
              value={term}
              onChange={(e) => setTerm(Number(e.target.value))}
              min="3"
              max="60"
              step="1"
              className="modal-consumerloan-slider"
            />
            <div className="modal-consumerloan-range">
              <span>3 мес.</span>
              <span>60 мес.</span>
            </div>
          </div>

          <div className="modal-consumerloan-rate">
            Ставка: {RATES.CONSUMER_LOAN}%
          </div>

          <div className="modal-consumerloan-result">
            <div className="modal-consumerloan-total">
              Ежемесячный платеж: {formatCurrency(monthlyPayment)} ₽
            </div>
          </div>

          <button type="submit" className="modal-consumerloan-submit">
            Оформить кредит
          </button>
        </form>
      </div>
    </div>
  );
};

export default ModalConsumerLoan;
