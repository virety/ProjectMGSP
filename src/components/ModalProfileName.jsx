import React, { useState } from 'react';
import { FaTimes } from 'react-icons/fa';
import './ModalProfileSettings.css';

const ModalProfileName = ({ show, onClose, onSave, currentFirstName, currentLastName }) => {
  const [firstName, setFirstName] = useState(currentFirstName);
  const [lastName, setLastName] = useState(currentLastName);
  const [error, setError] = useState('');

  const validateName = (name) => {
    return /^[А-ЯЁа-яё\s-]{2,30}$/.test(name);
  };

  const handleSave = () => {
    if (!validateName(firstName) || !validateName(lastName)) {
      setError('Имя и фамилия должны содержать только русские буквы, дефис и пробел (от 2 до 30 символов)');
      return;
    }
    onSave({ firstName, lastName });
    onClose();
  };

  if (!show) return null;

  return (
    <div className="modal-overlay">
      <div className="modal-profile-settings">
        <button className="modal-close" onClick={onClose}>
          <FaTimes />
        </button>
        <h2>Изменить имя и фамилию</h2>
        
        <div className="profile-form">
          <div className="form-group">
            <label>Имя</label>
            <input
              type="text"
              value={firstName}
              onChange={(e) => {
                setFirstName(e.target.value);
                setError('');
              }}
              placeholder="Введите имя"
            />
          </div>

          <div className="form-group">
            <label>Фамилия</label>
            <input
              type="text"
              value={lastName}
              onChange={(e) => {
                setLastName(e.target.value);
                setError('');
              }}
              placeholder="Введите фамилию"
            />
          </div>

          {error && <div className="form-error">{error}</div>}
        </div>

        <div className="modal-actions">
          <button className="modal-cancel" onClick={onClose}>Отмена</button>
          <button 
            className="modal-save" 
            onClick={handleSave}
            disabled={!firstName || !lastName}
          >
            Сохранить
          </button>
        </div>
      </div>
    </div>
  );
};

export default ModalProfileName; 