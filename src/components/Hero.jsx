import React from "react";
import "./Hero.css";
import "./HeroMedia.css";

const Hero = ({ onRegisterClick }) => (
  <section className="hero-section">
    <div className="hero-content">
      <div className="hero-title">Откройте для себя космический уровень<br/>финансовых возможностей</div>
      <div className="hero-subtitle">
        Ещё не с нами?{' '}
        <button className="hero-btn secondary hero-btn-register" onClick={onRegisterClick}>Зарегистрироваться</button>
      </div>
    </div>
    <img src="/images/planet.png" alt="Planet" className="hero-planet" />
  </section>
);

export default Hero; 