import React, { useState, useEffect } from "react";
import "./ModalAuth.css";

const ModalAuth = ({ show, onClose, onSuccess, tab, setTab }) => {
  const [login, setLogin] = useState("");
  const [password, setPassword] = useState("");
  const [surname, setSurname] = useState("");
  const [name, setName] = useState("");
  const [patronymic, setPatronymic] = useState("");
  const [phone, setPhone] = useState("");
  const [pin, setPin] = useState("");
  const [pinRepeat, setPinRepeat] = useState("");
  const [pinError, setPinError] = useState("");

  useEffect(() => { setPinError(""); }, [tab, show]);

  if (!show) return null;

  const handlePinChange = (e) => {
    const value = e.target.value.replace(/\D/g, "").slice(0, 4);
    setPin(value);
  };
  const handlePinRepeatChange = (e) => {
    const value = e.target.value.replace(/\D/g, "").slice(0, 4);
    setPinRepeat(value);
  };

  const handleRegister = (e) => {
    e.preventDefault();
    if (pin.length !== 4 || pin !== pinRepeat) {
      setPinError("Пин-код должен состоять из 4 цифр и совпадать");
      return;
    }
    setPinError("");
    onSuccess();
  };

  const handleLogin = (e) => {
    e.preventDefault();
    onSuccess();
  };

  return (
    <div className="modal-auth-overlay" onClick={onClose}>
      <div className="modal-auth" onClick={e => e.stopPropagation()}>
        <div className="modal-auth-tabs">
          <button className={tab === "login" ? "active" : ""} onClick={() => setTab("login")}>Вход</button>
          <button className={tab === "register" ? "active" : ""} onClick={() => setTab("register")}>Регистрация</button>
        </div>
        <div className="modal-auth-tabs-divider"></div>
        {tab === "login" ? (
          <>
            <div className="modal-auth-form-bg"></div>
            <form className="modal-auth-form" onSubmit={handleLogin}>
              <input type="text" placeholder="Логин" value={login} onChange={e => setLogin(e.target.value)} required />
              <input type="password" placeholder="Пароль" value={password} onChange={e => setPassword(e.target.value)} required />
              <div className="modal-auth-forgot">Забыли пароль?</div>
              <button type="submit" className="modal-auth-btn">Войти</button>
            </form>
          </>
        ) : (
          <>
            <div className="modal-auth-form-bg"></div>
            <form className="modal-auth-form" onSubmit={handleRegister}>
              <input type="text" placeholder="Фамилия" value={surname} onChange={e => setSurname(e.target.value)} required />
              <input type="text" placeholder="Имя" value={name} onChange={e => setName(e.target.value)} required />
              <input type="text" placeholder="Отчество (необязательно)" value={patronymic} onChange={e => setPatronymic(e.target.value)} />
              <input type="tel" placeholder="Номер телефона" value={phone} onChange={e => setPhone(e.target.value)} required />
              <input type="password" placeholder="Придумайте пинкод (4 цифры)" value={pin} onChange={handlePinChange} required />
              <input type="password" placeholder="Повторите пинкод" value={pinRepeat} onChange={handlePinRepeatChange} required />
              {pinError && <div className="modal-auth-error">{pinError}</div>}
              <button type="submit" className="modal-auth-btn">Зарегистрироваться</button>
            </form>
          </>
        )}
        <button className="modal-auth-close" onClick={onClose}>&times;</button>
      </div>
    </div>
  );
};

export default ModalAuth; 