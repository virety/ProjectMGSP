import React from "react";
import "./Header.css";
import { FaUserAstronaut, FaSignOutAlt } from "react-icons/fa";

const USER_NAME = "Анна";

const Header = ({ isCabinet, onCabinetClick, onLogout }) => {
  return (
    <header className="nyota-header">
      <div className="nyota-header__center">
        <span className="nyota-header__bank">Nyota Bank</span>
      </div>
      <div className="nyota-header__side nyota-header__side--left">
        <a href="#services" className="nyota-header__link header-link-services">Сервисы</a>
        <a href="#products" className="nyota-header__link header-link-products">Продукты</a>
      </div>
      <div className="nyota-header__side nyota-header__side--right">
        <a href="#mobile" className="nyota-header__link header-link-mobile">Мобильное приложение</a>
        {isCabinet ? (
          <div className="nyota-header__user header-link-cabinet" style={{cursor: 'pointer'}}>
            <div className="nyota-header__avatar">
              <FaUserAstronaut size={33} color="#fff" />
            </div>
            <span className="nyota-header__cabinet">{USER_NAME}</span>
          </div>
        ) : (
          <div className="nyota-header__user header-link-cabinet" onClick={onCabinetClick} style={{cursor: 'pointer'}}>
            <div className="nyota-header__avatar">
              <FaUserAstronaut size={33} color="#fff" />
            </div>
            <span className="nyota-header__cabinet">Личный кабинет</span>
          </div>
        )}
      </div>
      <div className="nyota-header__underline"></div>
    </header>
  );
};

export default Header; 