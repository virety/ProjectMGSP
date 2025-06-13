import React, { useState, useEffect } from "react";
import "./HeaderCabinet.css";
import { FaHome, FaUser, FaComments } from "react-icons/fa";
import { defaultAvatar } from './CabinetProfile';

const HeaderCabinet = ({ onLogout, activeScreen = 'main', onScreenChange }) => {
  const [userData, setUserData] = useState({
    firstName: 'Анна',
    lastName: 'Иванова',
    avatar: null,
  });

  useEffect(() => {
    // Update user data when it changes in the profile
    const updateUserData = () => {
      if (window.userData) {
        setUserData(window.userData);
      }
    };

    // Initial update
    updateUserData();

    // Set up an interval to check for changes
    const interval = setInterval(updateUserData, 1000);

    return () => clearInterval(interval);
  }, []);

  const renderNavButton = (screen, Icon, label) => (
    <button 
      className={`cabinet-header__nav-btn ${activeScreen === screen ? 'active' : ''}`}
      onClick={() => onScreenChange(screen)}
    >
      {React.createElement(Icon)}
      <span>{label}</span>
    </button>
  );

  return (
    <header className="cabinet-header">
      <div className="cabinet-header__left">
        <span className="cabinet-header__bank">NB</span>
      </div>
      <div className="cabinet-header__center">
        <div className="cabinet-header__nav">
          {renderNavButton('main', FaHome, 'Главная')}
          {renderNavButton('profile', FaUser, 'Профиль')}
          {renderNavButton('forum', FaComments, 'Форум')}
        </div>
        <span className="cabinet-header__welcome">Личный кабинет</span>
      </div>
      <div className="cabinet-header__right">
        <div className="cabinet-header__user-info">
          <div className="cabinet-header__avatar">
            {userData.avatar ? (
              <img src={userData.avatar} alt="Profile" />
            ) : (
              defaultAvatar
            )}
          </div>
          <span className="cabinet-header__user">{userData.firstName}</span>
        </div>
        <button className="cabinet-header-btn" onClick={onLogout}>Выйти</button>
      </div>
      <div className="nyota2-header__underline"></div>
    </header>
  );
};

export default HeaderCabinet; 