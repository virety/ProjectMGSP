import React, { useState, useEffect } from "react";
import { RATES } from "../constants/rates";
import "./ModalDepositCalc.css";

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
    <div className="modal-depositcalc-overlay" onClick={onClose}>
      <div className="modal-depositcalc" onClick={e => e.stopPropagation()}>
        <button className="modal-depositcalc-close" onClick={onClose}>×</button>
        
        {!showSuccess ? (
          <>
            <div className="modal-depositcalc-title">Калькулятор вклада</div>
            <div className="modal-depositcalc-form">
              <div className="modal-depositcalc-field">
                <label>Сумма вклада</label>
                <div className="modal-depositcalc-input-group">
                  <input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(Number(e.target.value))}
                    min="10000"
                    step="10000"
                    className="modal-depositcalc-input"
                  />
                  <span className="modal-depositcalc-currency">₽</span>
                </div>
              </div>

              <div className="modal-depositcalc-field">
                <label>Срок вклада: {term} {getMonthText(term)}</label>
                <input
                  type="range"
                  min="1"
                  max="36"
                  value={term}
                  onChange={(e) => setTerm(Number(e.target.value))}
                  className="modal-depositcalc-slider"
                />
                <div className="modal-depositcalc-slider-labels">
                  <span>1 месяц</span>
                  <span>36 месяцев</span>
                </div>
              </div>

              <div className="modal-depositcalc-rate">
                Процентная ставка: {rate}% годовых
              </div>

              <div className="modal-depositcalc-result">
                <div className="modal-depositcalc-total">
                  Итоговая сумма: {formatAmount(total)}
                </div>
                <div className="modal-depositcalc-profit">
                  {formatAmount(profit)} за период вклада
                </div>
              </div>

              <button 
                className="modal-depositcalc-submit"
                onClick={handleSubmit}
              >
                Открыть вклад
              </button>
            </div>
          </>
        ) : (
          <div className="modal-depositcalc-success">
            <h2>Вклад успешно открыт!</h2>
            <p>Деньги зачислены на ваш счет</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ModalDepositCalc;