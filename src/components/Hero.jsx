import React from "react";
import "./Hero.css";

const Hero = ({ onLoginClick, onRegisterClick }) => (
  <section className="hero-section">
    <div className="hero-title">Nyota Bank</div>
    <div className="hero-subtitle">Откройте для себя космический уровень<br/>финансовых возможностей</div>
    <div className="hero-buttons">
      <button className="hero-btn primary" onClick={onLoginClick}>Войти</button>
      <button className="hero-btn secondary" onClick={onRegisterClick}>Зарегистрироваться</button>
    </div>
  </section>
);

export default Hero; 