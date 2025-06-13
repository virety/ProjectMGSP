import React, { useState } from 'react';
import { FaTimes, FaEye, FaEyeSlash } from 'react-icons/fa';
import './ModalProfileSettings.css';

const ModalProfileSecurity = ({ show, onClose, onSave }) => {
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPasswords, setShowPasswords] = useState({
    current: false,
    new: false,
    confirm: false
  });
  const [error, setError] = useState('');

  const validatePassword = (password) => {
    return /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$/.test(password);
  };

  const handleSave = () => {
    if (!currentPassword || !newPassword || !confirmPassword) {
      setError('Все поля должны быть заполнены');
      return;
    }

    if (!validatePassword(newPassword)) {
      setError('Пароль должен содержать минимум 8 символов, включая заглавные и строчные буквы, и цифры');
      return;
    }

    if (newPassword !== confirmPassword) {
      setError('Пароли не совпадают');
      return;
    }

    onSave({ currentPassword, newPassword });
    onClose();
  };

  const togglePasswordVisibility = (field) => {
    setShowPasswords(prev => ({
      ...prev,
      [field]: !prev[field]
    }));
  };

  if (!show) return null;

  return (
    <div className="modal-overlay">
      <div className="modal-profile-settings">
        <button className="modal-close" onClick={onClose}>
          <FaTimes />
        </button>
        <h2>Изменить пароль</h2>
        
        <div className="profile-form">
          <div className="form-group">
            <label>Текущий пароль</label>
            <div className="password-input">
              <input
                type={showPasswords.current ? "text" : "password"}
                value={currentPassword}
                onChange={(e) => {
                  setCurrentPassword(e.target.value);
                  setError('');
                }}
                placeholder="Введите текущий пароль"
              />
              <button 
                type="button"
                className="toggle-password"
                onClick={() => togglePasswordVisibility('current')}
              >
                {showPasswords.current ? <FaEyeSlash /> : <FaEye />}
              </button>
            </div>
          </div>

          <div className="form-group">
            <label>Новый пароль</label>
            <div className="password-input">
              <input
                type={showPasswords.new ? "text" : "password"}
                value={newPassword}
                onChange={(e) => {
                  setNewPassword(e.target.value);
                  setError('');
                }}
                placeholder="Введите новый пароль"
              />
              <button 
                type="button"
                className="toggle-password"
                onClick={() => togglePasswordVisibility('new')}
              >
                {showPasswords.new ? <FaEyeSlash /> : <FaEye />}
              </button>
            </div>
          </div>

          <div className="form-group">
            <label>Подтвердите новый пароль</label>
            <div className="password-input">
              <input
                type={showPasswords.confirm ? "text" : "password"}
                value={confirmPassword}
                onChange={(e) => {
                  setConfirmPassword(e.target.value);
                  setError('');
                }}
                placeholder="Подтвердите новый пароль"
              />
              <button 
                type="button"
                className="toggle-password"
                onClick={() => togglePasswordVisibility('confirm')}
              >
                {showPasswords.confirm ? <FaEyeSlash /> : <FaEye />}
              </button>
            </div>
          </div>

          {error && <div className="form-error">{error}</div>}
        </div>

        <div className="modal-actions">
          <button className="modal-cancel" onClick={onClose}>Отмена</button>
          <button 
            className="modal-save" 
            onClick={handleSave}
            disabled={!currentPassword || !newPassword || !confirmPassword}
          >
            Сохранить
          </button>
        </div>
      </div>
    </div>
  );
};

export default ModalProfileSecurity; 