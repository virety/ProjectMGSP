import React, { useState, useEffect } from 'react';
import './ModalTransfer.css';
import { FaTimes } from 'react-icons/fa';

const TransferTab = ({ type, onSubmit, userCards }) => {
  const [fromCardId, setFromCardId] = useState(userCards[0]?.id || '');
  const [amount, setAmount] = useState('');
  const [recipient, setRecipient] = useState('');
  const [comment, setComment] = useState('');
  const [error, setError] = useState('');

  const selectedCardData = userCards.find(card => card.id === fromCardId);
  const maxAmount = selectedCardData ? parseFloat(String(selectedCardData.balance).replace(/,/g, '')) : 0;

  const formatBalance = (balance, currency = '₽') => {
    const numericBalance = parseFloat(String(balance).replace(/,/g, ''));
    return `${numericBalance.toLocaleString('ru-RU')} ${currency}`;
  };

  useEffect(() => {
    // Reset amount if it exceeds new card's balance
    if (parseFloat(amount) > maxAmount) {
      setAmount('');
      setError('');
    }
  }, [fromCardId, maxAmount, amount]);

  const handleAmountChange = (value) => {
    const numValue = parseFloat(value);
    if (value === '') {
      setAmount('');
      setError('');
    } else if (isNaN(numValue)) {
      setError('Введите корректную сумму');
    } else if (numValue <= 0) {
      setError('Сумма должна быть больше 0');
    } else if (numValue > maxAmount) {
      setAmount(maxAmount.toString());
      setError('');
    } else {
      setAmount(value);
      setError('');
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!error && amount && recipient) {
      onSubmit({
        type,
        fromCardId,
        amount,
        recipient,
        comment
      });
    }
  };

  const getPlaceholder = () => {
    switch (type) {
      case 'recipient':
        return 'ФИО получателя';
      case 'phone':
        return 'Номер телефона';
      case 'card':
        return 'Номер карты';
      default:
        return '';
    }
  };

  return (
    <form onSubmit={handleSubmit} className="modal-transfer-form">
      <div className="modal-transfer-field">
        <label className="modal-transfer-label">
          {type === 'recipient' ? 'ФИО получателя' : type === 'phone' ? 'Номер телефона' : 'Номер карты'}
        </label>
        <input
          type={type === 'phone' ? 'tel' : 'text'}
          value={recipient}
          onChange={(e) => setRecipient(e.target.value)}
          className="modal-transfer-input"
          placeholder={getPlaceholder()}
          required
        />
      </div>

      <div className="modal-transfer-field">
        <label className="modal-transfer-label">Выберите карту</label>
        <select
          value={fromCardId}
          onChange={(e) => setFromCardId(e.target.value)}
          className="modal-transfer-select"
          required
        >
          {userCards.map(card => (
            <option key={card.id} value={card.id}>
              {card.name} - {formatBalance(card.balance, card.currency)}
            </option>
          ))}
        </select>
      </div>

      <div className="modal-transfer-field">
        <label className="modal-transfer-label">Сумма перевода</label>
        <input
          type="number"
          value={amount}
          onChange={(e) => handleAmountChange(e.target.value)}
          className="modal-transfer-input"
          placeholder={`Максимум ${formatBalance(maxAmount)}`}
          min="1"
          max={maxAmount}
          required
        />
        {error && <div className="modal-transfer-error">{error}</div>}
      </div>

      <div className="modal-transfer-field">
        <label className="modal-transfer-label">Комментарий</label>
        <input
          type="text"
          value={comment}
          onChange={(e) => setComment(e.target.value)}
          className="modal-transfer-input"
          placeholder="Добавьте комментарий"
        />
      </div>

      <button 
        type="submit" 
        className="modal-transfer-submit"
        disabled={!!error || !amount || !recipient}
      >
        Отправить
      </button>
    </form>
  );
};

const ModalTransfer = ({ show, onClose, userCards, onConfirmTransfer }) => {
  const [activeTab, setActiveTab] = useState('recipient');
  const [showSuccess, setShowSuccess] = useState(false);

  if (!show) return null;

  const handleTransfer = (transferData) => {
    onConfirmTransfer(transferData);
    setShowSuccess(true);
  };

  const handleClose = () => {
    setShowSuccess(false);
    onClose();
  };

  if (showSuccess) {
    return (
      <div className="modal-transfer-overlay">
        <div className="modal-transfer">
          <button className="modal-transfer-close" onClick={handleClose}>
            <FaTimes />
          </button>
          <div className="modal-transfer-title">Перевод выполнен!</div>
          <p className="modal-transfer-success-text">
            Ваш перевод успешно отправлен.
          </p>
          <button className="modal-transfer-submit" onClick={handleClose}>
            Закрыть
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="modal-transfer-overlay">
      <div className="modal-transfer">
        <button className="modal-transfer-close" onClick={onClose}>
          <FaTimes />
        </button>
        <div className="modal-transfer-title">Перевод</div>
        
        <div className="modal-transfer-tabs">
          <button
            className={`modal-transfer-tab ${activeTab === 'recipient' ? 'active' : ''}`}
            onClick={() => setActiveTab('recipient')}
          >
            Получатель
          </button>
          <button
            className={`modal-transfer-tab ${activeTab === 'phone' ? 'active' : ''}`}
            onClick={() => setActiveTab('phone')}
          >
            Номер телефона
          </button>
          <button
            className={`modal-transfer-tab ${activeTab === 'card' ? 'active' : ''}`}
            onClick={() => setActiveTab('card')}
          >
            Номер карты
          </button>
        </div>

        <div className="modal-transfer-content">
          <TransferTab
            type={activeTab}
            onSubmit={handleTransfer}
            userCards={userCards}
          />
        </div>
      </div>
    </div>
  );
};

export default ModalTransfer; 