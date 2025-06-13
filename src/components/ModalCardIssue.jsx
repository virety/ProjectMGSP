import React, { useState, useEffect } from 'react';
import './ModalCardIssue.css';
import { FaTimes } from 'react-icons/fa';

const ModalCardIssue = ({ show, onClose }) => {
  const [cardName, setCardName] = useState('');
  const [cardNumber, setCardNumber] = useState('');
  const [issueDate, setIssueDate] = useState('');
  const [expiryDate, setExpiryDate] = useState('');
  const [showSuccess, setShowSuccess] = useState(false);

  useEffect(() => {
    // Генерация номера карты
    const generateCardNumber = () => {
      const prefix = '4276';
      const numbers = Array.from({ length: 12 }, () => Math.floor(Math.random() * 10)).join('');
      return `${prefix} ${numbers.slice(0, 4)} ${numbers.slice(4, 8)} ${numbers.slice(8, 12)}`;
    };

    // Генерация даты выпуска (текущая дата)
    const generateIssueDate = () => {
      const today = new Date();
      return today.toLocaleDateString('ru-RU');
    };

    // Генерация срока действия (текущая дата + 3 года)
    const generateExpiryDate = () => {
      const today = new Date();
      const expiry = new Date(today.setFullYear(today.getFullYear() + 3));
      return expiry.toLocaleDateString('ru-RU');
    };

    setCardNumber(generateCardNumber());
    setIssueDate(generateIssueDate());
    setExpiryDate(generateExpiryDate());
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();
    setShowSuccess(true);
  };

  if (!show) return null;

  if (showSuccess) {
    return (
      <div className="modal-cardissue-overlay">
        <div className="modal-cardissue">
          <button className="modal-cardissue-close" onClick={onClose}><FaTimes /></button>
          <div className="modal-cardissue-title">Заявка принята!</div>
          <p className="modal-cardissue-success-text">
            Ваша карта будет выпущена в ближайшее время. 
            Мы уведомим вас, когда она будет готова к получению.
          </p>
          <button className="modal-cardissue-submit" onClick={onClose}>
            Закрыть
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="modal-cardissue-overlay">
      <div className="modal-cardissue">
        <button className="modal-cardissue-close" onClick={onClose}><FaTimes /></button>
        <div className="modal-cardissue-title">Выпуск новой карты</div>
        <form onSubmit={handleSubmit} className="modal-cardissue-form">
          <div className="modal-cardissue-field">
            <label className="modal-cardissue-label">Название карты</label>
            <input
              type="text"
              value={cardName}
              onChange={(e) => setCardName(e.target.value)}
              className="modal-cardissue-input"
              placeholder="Например: Моя дебетовая карта"
              required
            />
          </div>

          <div className="modal-cardissue-field">
            <label className="modal-cardissue-label">Номер карты</label>
            <input
              type="text"
              value={cardNumber}
              className="modal-cardissue-input"
              readOnly
            />
          </div>

          <div className="modal-cardissue-field">
            <label className="modal-cardissue-label">Дата выпуска</label>
            <input
              type="text"
              value={issueDate}
              className="modal-cardissue-input"
              readOnly
            />
          </div>

          <div className="modal-cardissue-field">
            <label className="modal-cardissue-label">Срок действия</label>
            <input
              type="text"
              value={expiryDate}
              className="modal-cardissue-input"
              readOnly
            />
          </div>

          <button type="submit" className="modal-cardissue-submit">
            Создать карту
          </button>
        </form>
      </div>
    </div>
  );
};

export default ModalCardIssue; 