import React, { useState, useEffect } from "react";
import { RATES } from "../constants/rates";
import "./ModalDepositCalc.css";
import { FaTimes } from "react-icons/fa";

const ModalDepositCalc = ({ show, onClose }) => {
  const [amount, setAmount] = useState(100000);
  const [term, setTerm] = useState(1);
  const [total, setTotal] = useState(0);
  const [profit, setProfit] = useState(0);
  const [showSuccess, setShowSuccess] = useState(false);
  const rate = RATES.DEPOSIT;

  const getMonthText = (months) => {
    const lastDigit = months % 10;
    const lastTwoDigits = months % 100;
    
    if (lastTwoDigits >= 11 && lastTwoDigits <= 19) {
      return 'месяцев';
    }
    
    if (lastDigit === 1) {
      return 'месяц';
    }
    
    if (lastDigit >= 2 && lastDigit <= 4) {
      return 'месяца';
    }
    
    return 'месяцев';
  };

  useEffect(() => {
    const calculatedTotal = amount * (1 + (rate / 100) * (term / 12));
    setTotal(Math.round(calculatedTotal));
    setProfit(Math.round(calculatedTotal - amount));
  }, [amount, term, rate]);

  if (!show) return null;

  const formatAmount = (value) => {
    return new Intl.NumberFormat('ru-RU', {
      style: 'currency',
      currency: 'RUB',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(value);
  };

  if (showSuccess) {
    return (
      <div className="modal-depositcalc-overlay">
        <div className="modal-depositcalc">
          <button className="modal-depositcalc-close" onClick={onClose}><FaTimes /></button>
          <div className="modal-depositcalc-title">Заявка принята!</div>
          <p className="modal-depositcalc-success-text">
            Ваша заявка на открытие вклада принята.
            Сумма: {formatAmount(amount)}<br />
            Срок: {term} {getMonthText(term)}<br />
            Ожидаемый доход: {formatAmount(profit)}
          </p>
          <button className="modal-depositcalc-submit" onClick={onClose}>
            Закрыть
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="modal-depositcalc-overlay">
      <div className="modal-depositcalc">
        <button className="modal-depositcalc-close" onClick={onClose}><FaTimes /></button>
        <div className="modal-depositcalc-title">Рассчитать вклад</div>
        <form className="modal-depositcalc-form">
          <div className="modal-depositcalc-field">
            <label className="modal-depositcalc-label">Сумма вклада</label>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(Number(e.target.value))}
              min="10000"
              step="1000"
              className="modal-depositcalc-input"
            />
            <input
              type="range"
              value={amount}
              onChange={(e) => setAmount(Number(e.target.value))}
              min="10000"
              max="5000000"
              step="10000"
              className="modal-depositcalc-slider"
            />
            <div className="modal-depositcalc-range">
              <span>10 000 ₽</span>
              <span>5 000 000 ₽</span>
            </div>
          </div>

          <div className="modal-depositcalc-field">
            <label className="modal-depositcalc-label">Срок вклада</label>
            <input
              type="number"
              value={term}
              onChange={(e) => setTerm(Number(e.target.value))}
              min="1"
              max="60"
              className="modal-depositcalc-input"
            />
            <input
              type="range"
              value={term}
              onChange={(e) => setTerm(Number(e.target.value))}
              min="1"
              max="60"
              className="modal-depositcalc-slider"
            />
            <div className="modal-depositcalc-range">
              <span>1 месяц</span>
              <span>60 месяцев</span>
            </div>
          </div>

          <div className="modal-depositcalc-rate">
            Процентная ставка: {rate}% годовых
          </div>

          <div className="modal-depositcalc-result">
            <div className="modal-depositcalc-total">
              Сумма к получению: {formatAmount(total)}
            </div>
            <div className="modal-depositcalc-profit">
              Доход: {formatAmount(profit)}
            </div>
          </div>

          <button 
            type="button"
            className="modal-depositcalc-submit"
            onClick={() => setShowSuccess(true)}
          >
            Открыть вклад
          </button>
        </form>
      </div>
    </div>
  );
};

export default ModalDepositCalc;