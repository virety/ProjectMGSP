import React, { useState } from 'react';
import './ModalTopUp.css';
import { FaTimes } from 'react-icons/fa';

const ModalTopUp = ({ show, onClose, onConfirm, cardName }) => {
  const [amount, setAmount] = useState('');
  const [error, setError] = useState('');

  if (!show) {
    return null;
  }

  const handleAmountChange = (e) => {
    const value = e.target.value;
    if (value === '' || (/^\d+$/.test(value) && parseInt(value, 10) > 0)) {
      setAmount(value);
      setError('');
    } else {
       setError('Введите целое положительное число');
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (amount && !error) {
      onConfirm(parseInt(amount, 10));
      onClose(); // Close modal on success
    } else if (!amount) {
      setError('Введите сумму');
    }
  };

  return (
    <div className="modal-topup-overlay" onClick={onClose}>
      <div className="modal-topup" onClick={e => e.stopPropagation()}>
        <button className="modal-topup-close" onClick={onClose}>
          <FaTimes />
        </button>
        <h2 className="modal-topup-title">Пополнение карты</h2>
        <p className="modal-topup-card-name">{cardName}</p>

        <form onSubmit={handleSubmit} className="topup-form">
          <label htmlFor="topup-amount" className="topup-label">Сумма пополнения</label>
          <div className="topup-input-wrapper">
            <input
              id="topup-amount"
              type="text"
              value={amount}
              onChange={handleAmountChange}
              className="topup-input"
              placeholder="Например, 1000"
              autoFocus
            />
            <span className="topup-currency">₽</span>
          </div>
          {error && <p className="topup-error">{error}</p>}
          <button type="submit" className="topup-submit-btn">
            Пополнить
          </button>
        </form>
      </div>
    </div>
  );
};

export default ModalTopUp; 