import React, { useState, useRef, useEffect } from "react";
import "./HeaderCabinet.css";
import { FaUserAstronaut } from "react-icons/fa";

const USER_NAME = "Анна";

const HeaderCabinet = ({ onLogout }) => {
  const [showMenu, setShowMenu] = useState(false);
  const avatarRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (avatarRef.current && !avatarRef.current.contains(event.target)) {
        setShowMenu(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  const handleAvatarClick = () => setShowMenu((v) => !v);
  const handleLogoutClick = () => {
    setShowMenu(false);
    onLogout();
  };

  return (
    <header className="cabinet-header">
      <div className="cabinet-header__left">
        <span className="cabinet-header__bank">NB</span>
      </div>
      <div className="cabinet-header__center">
        <span className="cabinet-header__welcome">Личный кабинет</span>
      </div>
      <div className="cabinet-header__right">
        <div className="cabinet-header__user-info">
          <div className="cabinet-header__avatar" ref={avatarRef} onClick={handleAvatarClick} style={{cursor: 'pointer'}}>
            <FaUserAstronaut size={33} color="#fff" />
          </div>
          <span className="cabinet-header__user">{USER_NAME}</span>
        </div>
        {showMenu && (
          <div className="cabinet-header-popover">
            <button className="cabinet-header-popover-btn" onClick={handleLogoutClick}>Выйти</button>
          </div>
        )}
      </div>
      <div className="nyota2-header__underline"></div>
    </header>
  );
};

export default HeaderCabinet; 