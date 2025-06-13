import React, { useState } from 'react';
import './ModalResetPassword.css';

export const ModalResetPassword = ({ show, onClose }) => {
  const [recoveryMethod, setRecoveryMethod] = useState('phone');
  const [contact, setContact] = useState('');
  const [showVerification, setShowVerification] = useState(false);
  const [verificationCode, setVerificationCode] = useState(['', '', '', '', '', '']);
  
  const handleMethodChange = (method) => {
    setRecoveryMethod(method);
    setContact('');
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setShowVerification(true);
  };

  const handleCodeChange = (index, value) => {
    if (value.length <= 1 && /^\d*$/.test(value)) {
      const newCode = [...verificationCode];
      newCode[index] = value;
      setVerificationCode(newCode);
      
      // Auto-focus next input
      if (value && index < 5) {
        const nextInput = document.querySelector(`input[name="code-${index + 1}"]`);
        if (nextInput) nextInput.focus();
      }
    }
  };

  const handleKeyDown = (index, e) => {
    if (e.key === 'Backspace' && !verificationCode[index] && index > 0) {
      const prevInput = document.querySelector(`input[name="code-${index - 1}"]`);
      if (prevInput) prevInput.focus();
    }
  };

  if (!show) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={e => e.stopPropagation()}>
        {!showVerification ? (
          <form onSubmit={handleSubmit} className="modal-reset-form">
            <h2>Восстановление пароля</h2>
            
            <div className="recovery-methods">
              <label className="recovery-method">
                <input
                  type="radio"
                  name="recovery"
                  value="phone"
                  checked={recoveryMethod === 'phone'}
                  onChange={() => handleMethodChange('phone')}
                />
                <span className="radio-custom"></span>
                <span>Номер телефона</span>
              </label>
              
              <label className="recovery-method">
                <input
                  type="radio"
                  name="recovery"
                  value="email"
                  checked={recoveryMethod === 'email'}
                  onChange={() => handleMethodChange('email')}
                />
                <span className="radio-custom"></span>
                <span>E-mail</span>
              </label>
            </div>

            <input
              type={recoveryMethod === 'email' ? 'email' : 'tel'}
              placeholder={recoveryMethod === 'email' ? 'E-mail' : 'Номер телефона'}
              value={contact}
              onChange={(e) => setContact(e.target.value)}
              required
            />

            <button type="submit" className="modal-auth-btn">Далее</button>
          </form>
        ) : (
          <div className="verification-form">
            <h2>Введите код подтверждения</h2>
            <p>Код был отправлен на {recoveryMethod === 'email' ? 'E-mail' : 'номер телефона'}</p>
            
            <div className="verification-inputs">
              {verificationCode.map((digit, index) => (
                <input
                  key={index}
                  type="text"
                  name={`code-${index}`}
                  value={digit}
                  onChange={(e) => handleCodeChange(index, e.target.value)}
                  onKeyDown={(e) => handleKeyDown(index, e)}
                  maxLength={1}
                  autoFocus={index === 0}
                />
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}; 