import React from 'react';
import { FaTelegram, FaVk, FaAndroid } from 'react-icons/fa';
import { SiHuawei } from 'react-icons/si';
import './BottomInfo.css';

const BottomInfo = () => {
  return (
    <div className="bottom-info">
      <div className="bottom-info-container">
        <div className="bottom-info-grid">
          <div className="bottom-info-section">
            <h3>О банке</h3>
            <ul>
              <li><a href="#about">О нас</a></li>
              <li><a href="#career">Карьера</a></li>
              <li><a href="#press">Пресс-центр</a></li>
              <li><a href="#contacts">Контакты</a></li>
            </ul>
          </div>
          
          <div className="bottom-info-section">
            <h3>Сервисы</h3>
            <ul>
              <li><a href="#online">Онлайн-банк</a></li>
              <li><a href="#investments">Инвестиции</a></li>
              <li><a href="#insurance">Страхование</a></li>
              <li><a href="#business">Бизнесу</a></li>
            </ul>
          </div>
          
          <div className="bottom-info-section">
            <h3>Безопасность</h3>
            <ul>
              <li><a href="#security">Безопасность</a></li>
              <li><a href="#fraud">Мошенничество</a></li>
              <li><a href="#support">Поддержка</a></li>
            </ul>
          </div>
          
          <div className="bottom-info-section">
            <h3>Мобильное приложение</h3>
            <div className="bottom-info-apps">
              <a href="#rustore" className="app-store-link">
                <img src="/images/rustore.png" alt="RuStore" />
              </a>
              <a href="#android" className="app-store-link">
                <FaAndroid size={24} />
              </a>
              <a href="#huawei" className="app-store-link">
                <SiHuawei size={24} />
              </a>
            </div>
            <div className="bottom-info-social">
              <a href="#telegram" aria-label="Telegram">
                <FaTelegram />
              </a>
              <a href="#vk" aria-label="VK">
                <FaVk />
              </a>
            </div>
          </div>
        </div>
        
        <div className="bottom-info-legal">
          <div className="bottom-info-copyright">
            Nyota Bank © 2025 — Космические финансы для каждого
          </div>
          <div className="bottom-info-contacts">
            <p>8 800 555 35 35 — Бесплатный звонок по России</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BottomInfo; 