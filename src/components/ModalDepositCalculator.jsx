import React, { useState, useEffect } from 'react';
import { FaTimes } from 'react-icons/fa';
import './ModalDepositCalculator.css';

const DEPOSIT_RATE = 0.05; // 5% годовых

const ModalDepositCalculator = ({ show, onClose }) => {
  const [amount, setAmount] = useState(100000);
  const [term, setTerm] = useState(12);
  const [total, setTotal] = useState(0);
  const [profit, setProfit] = useState(0);

  useEffect(() => {
    const calculatedTotal = amount * (1 + DEPOSIT_RATE * (term / 12));
    const calculatedProfit = calculatedTotal - amount;
    setTotal(calculatedTotal);
    setProfit(calculatedProfit);
  }, [amount, term]);

  const formatCurrency = (value) => {
    return new Intl.NumberFormat('ru-RU', {
      style: 'currency',
      currency: 'RUB',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(value);
  };

  if (!show) return null;

  return (
    <div className="modal-overlay">
      <div className="deposit-calculator">
        <button className="modal-close" onClick={onClose}>
          <FaTimes />
        </button>
        <h2>Калькулятор вклада</h2>
        <div className="calculator-form">
          <div className="form-group">
            <label>Сумма вклада</label>
            <div className="input-group">
              <input
                type="number"
                value={amount}
                onChange={(e) => setAmount(Number(e.target.value))}
                min="1000"
                max="10000000"
              />
              <span className="currency">₽</span>
            </div>
            <input
              type="range"
              className="slider"
              min="1000"
              max="10000000"
              step="1000"
              value={amount}
              onChange={(e) => setAmount(Number(e.target.value))}
            />
            <div className="range-labels">
              <span>1 000 ₽</span>
              <span>10 000 000 ₽</span>
            </div>
          </div>

          <div className="form-group">
            <label>Срок вклада</label>
            <div className="input-group">
              <input
                type="number"
                value={term}
                onChange={(e) => setTerm(Number(e.target.value))}
                min="1"
                max="36"
              />
              <span className="currency">мес.</span>
            </div>
            <input
              type="range"
              className="slider"
              min="1"
              max="36"
              value={term}
              onChange={(e) => setTerm(Number(e.target.value))}
            />
            <div className="range-labels">
              <span>1 мес.</span>
              <span>36 мес.</span>
            </div>
          </div>

          <div className="rate-display">
            Процентная ставка: <span className="rate-value">{DEPOSIT_RATE * 100}%</span>
          </div>

          <div className="results">
            <div className="result-item">
              <span>Сумма к выплате:</span>
              <span className="result-value">{formatCurrency(total)}</span>
            </div>
            <div className="result-item">
              <span>Доход по вкладу:</span>
              <span className="result-value profit">{formatCurrency(profit)}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ModalDepositCalculator; 