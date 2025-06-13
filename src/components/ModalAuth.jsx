import React, { useState, useEffect } from "react";
import "./ModalAuth.css";
import { FaTimes } from "react-icons/fa";

const ModalAuth = ({ show, onClose, onSuccess, tab, setTab }) => {
  const [login, setLogin] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [surname, setSurname] = useState("");
  const [patronymic, setPatronymic] = useState("");
  const [phone, setPhone] = useState("");
  const [pin, setPin] = useState("");
  const [pinRepeat, setPinRepeat] = useState("");
  const [pinError, setPinError] = useState("");
  const [email, setEmail] = useState("");
  const [isResetPassword, setIsResetPassword] = useState(false);
  const [recoveryMethod, setRecoveryMethod] = useState('phone');
  const [contact, setContact] = useState('');
  const [showVerification, setShowVerification] = useState(false);
  const [verificationCode, setVerificationCode] = useState(['', '', '', '', '', '']);

  useEffect(() => { 
    setPinError(""); 
    setIsResetPassword(false);
    setShowVerification(false);
  }, [tab, show]);

  const handleLogin = (e) => {
    e.preventDefault();
    onSuccess();
  };

  const handleRegistration = (e) => {
    e.preventDefault();
    onSuccess();
  };

  const handleForgotPassword = (e) => {
    e.preventDefault();
    setIsResetPassword(true);
  };

  const handleMethodChange = (method) => {
    setRecoveryMethod(method);
    setContact('');
  };

  const handleResetSubmit = (e) => {
    e.preventDefault();
    setShowVerification(true);
  };

  const handleCodeChange = (index, value) => {
    if (value.length <= 1 && /^\d*$/.test(value)) {
      const newCode = [...verificationCode];
      newCode[index] = value;
      setVerificationCode(newCode);
      
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

  const handleBackToLogin = () => {
    setIsResetPassword(false);
    setShowVerification(false);
    setVerificationCode(['', '', '', '', '', '']);
    setContact('');
  };

  if (!show) return null;

  return (
    <div className="modal-auth-overlay" onClick={onClose}>
      <div className="modal-auth" onClick={e => e.stopPropagation()}>
        {!isResetPassword ? (
          <>
            <div className="modal-auth-tabs">
              <div className={tab === "login" ? "modal-auth-tab active" : "modal-auth-tab"} onClick={() => setTab("login")}>
                Вход
              </div>
              <div className={tab === "registration" ? "modal-auth-tab active" : "modal-auth-tab"} onClick={() => setTab("registration")}>
                Регистрация
              </div>
            </div>

            {tab === "login" ? (
              <>
                <div className="modal-auth-form-bg"></div>
                <form className="modal-auth-form" onSubmit={handleLogin}>
                  <input 
                    type="text" 
                    placeholder="E-mail / Номер телефона / Номер карты" 
                    value={login} 
                    onChange={e => setLogin(e.target.value)} 
                    required 
                  />
                  <input type="password" placeholder="Пароль" value={password} onChange={e => setPassword(e.target.value)} required />
                  <div className="modal-auth-forgot" onClick={handleForgotPassword}>Забыли пароль?</div>
                  <button type="submit" className="modal-auth-btn">Войти</button>
                </form>
              </>
            ) : (
              <>
                <div className="modal-auth-form-bg"></div>
                <form className="modal-auth-form" onSubmit={handleRegistration}>
                  <input type="text" placeholder="Фамилия" value={surname} onChange={e => setSurname(e.target.value)} required />
                  <input type="text" placeholder="Имя" value={name} onChange={e => setName(e.target.value)} required />
                  <input type="text" placeholder="Отчество (необязательно)" value={patronymic} onChange={e => setPatronymic(e.target.value)} />
                  <input type="tel" placeholder="Номер телефона" value={phone} onChange={e => setPhone(e.target.value)} required />
                  <input type="email" placeholder="E-mail" value={email} onChange={e => setEmail(e.target.value)} required />
                  <input type="password" placeholder="Придумайте пароль" value={pin} onChange={e => setPin(e.target.value)} required />
                  <input type="password" placeholder="Повторите пароль" value={pinRepeat} onChange={e => setPinRepeat(e.target.value)} required />
                  {pinError && <div className="modal-auth-error">{pinError}</div>}
                  <button type="submit" className="modal-auth-btn">Зарегистрироваться</button>
                </form>
              </>
            )}
          </>
        ) : (
          <>
            <div className="modal-auth-header">
              <button className="modal-auth-back" onClick={handleBackToLogin}>
                ← Назад
              </button>
              <h2>Восстановление пароля</h2>
            </div>

            {!showVerification ? (
              <form onSubmit={handleResetSubmit} className="modal-reset-form">
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
                <button type="button" className="modal-auth-btn" onClick={() => console.log('Код подтвержден')}>
                  Подтвердить
                </button>
              </div>
            )}
          </>
        )}
        <button 
          className="modal-auth-close" 
          onClick={onClose}
        >
          <FaTimes />
        </button>
      </div>
    </div>
  );
};

export default ModalAuth; 