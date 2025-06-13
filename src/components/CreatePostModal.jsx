import React, { useState, useEffect } from 'react';
import './CreatePostModal.css';
import { FaTimes } from 'react-icons/fa';

const AVAILABLE_STATUSES = [
  'Трейдер',
  'Аналитик',
  'Инвестор',
  'Финансовый консультант',
  'Начинающий трейдер'
];

const AVAILABLE_AVATARS = [
  { emoji: '📊', label: 'График' },
  { emoji: '📈', label: 'Рост' },
  { emoji: '📉', label: 'Падение' },
  { emoji: '💹', label: 'Курс' },
  { emoji: '🏦', label: 'Банк' },
  { emoji: '💼', label: 'Портфель' },
  { emoji: '🎯', label: 'Цель' },
  { emoji: '⚡', label: 'Молния' }
];

const CURRENCY_PAIRS = [
  { value: 'EUR/RUB', label: 'EUR/RUB - Евро/Рубль' },
  { value: 'USD/RUB', label: 'USD/RUB - Доллар/Рубль' },
  { value: 'GBP/RUB', label: 'GBP/RUB - Фунт/Рубль' },
  { value: 'CNY/RUB', label: 'CNY/RUB - Юань/Рубль' },
  { value: 'JPY/RUB', label: 'JPY/RUB - Иена/Рубль' },
  { value: 'CHF/RUB', label: 'CHF/RUB - Франк/Рубль' }
];

const CreatePostModal = ({ isOpen, onClose, onSubmit }) => {
  const [formData, setFormData] = useState({
    currency: 'EUR/RUB',
    prediction: 'Рост',
    confidence: 50,
    description: ''
  });

  const [selectedStatus, setSelectedStatus] = useState('Трейдер');
  const [selectedAvatar, setSelectedAvatar] = useState(AVAILABLE_AVATARS[0]);
  const [userName, setUserName] = useState('');

  useEffect(() => {
    // Получаем имя и фамилию пользователя из window.userData
    if (window.userData) {
      const firstName = window.userData.firstName || '';
      const lastName = window.userData.lastName || '';
      const fullName = [firstName, lastName].filter(Boolean).join(' ');
      setUserName(fullName || 'Пользователь');
    }
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit({
      ...formData,
      author: {
        name: userName,
        role: selectedStatus,
        avatar: selectedAvatar.emoji
      }
    });
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay">
      <div className="modal-content create-post-modal">
        <button className="modal-close" onClick={onClose}>
          <FaTimes />
        </button>
        
        <div className="modal-header">
          <h2>Создать прогноз</h2>
          <div className="user-info">
            <div className="user-avatar">
              {selectedAvatar.emoji}
            </div>
            <div className="user-details">
              <div className="user-name">{userName}</div>
              <div className="user-status">{selectedStatus}</div>
            </div>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="create-post-form">
          <div className="form-section">
            <h3>Выберите статус</h3>
            <div className="status-options">
              {AVAILABLE_STATUSES.map(status => (
                <button
                  key={status}
                  type="button"
                  className={`status-btn ${selectedStatus === status ? 'active' : ''}`}
                  onClick={() => setSelectedStatus(status)}
                >
                  {status}
                </button>
              ))}
            </div>
          </div>

          <div className="form-section">
            <h3>Выберите аватар</h3>
            <div className="avatar-options">
              {AVAILABLE_AVATARS.map(avatar => (
                <button
                  key={avatar.emoji}
                  type="button"
                  className={`avatar-btn ${selectedAvatar.emoji === avatar.emoji ? 'active' : ''}`}
                  onClick={() => setSelectedAvatar(avatar)}
                  title={avatar.label}
                >
                  {avatar.emoji}
                </button>
              ))}
            </div>
          </div>

          <div className="form-section">
            <h3>Валютная пара</h3>
            <div className="currency-select">
              <select 
                value={formData.currency}
                onChange={(e) => setFormData({...formData, currency: e.target.value})}
              >
                {CURRENCY_PAIRS.map(pair => (
                  <option key={pair.value} value={pair.value}>
                    {pair.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="form-section">
            <h3>Тип прогноза</h3>
            <div className="prediction-options">
              <button
                type="button"
                className={`prediction-btn ${formData.prediction === 'Рост' ? 'active рост' : ''}`}
                onClick={() => setFormData({...formData, prediction: 'Рост'})}
              >
                Рост
              </button>
              <button
                type="button"
                className={`prediction-btn ${formData.prediction === 'Падение' ? 'active падение' : ''}`}
                onClick={() => setFormData({...formData, prediction: 'Падение'})}
              >
                Падение
              </button>
            </div>
          </div>

          <div className="form-section">
            <h3>Уверенность в прогнозе</h3>
            <div className="confidence-slider">
              <input
                type="range"
                min="0"
                max="100"
                value={formData.confidence}
                onChange={(e) => setFormData({...formData, confidence: parseInt(e.target.value)})}
              />
              <div className="confidence-value">{formData.confidence}%</div>
            </div>
          </div>

          <div className="form-section">
            <h3>Описание прогноза</h3>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              placeholder="Опишите ваш прогноз и его обоснование..."
              rows="4"
            />
          </div>

          <button type="submit" className="submit-btn">
            Опубликовать прогноз
          </button>
        </form>
      </div>
    </div>
  );
};

export default CreatePostModal; 