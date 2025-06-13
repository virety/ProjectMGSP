import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { FaHome, FaUser, FaComments } from 'react-icons/fa';
import './Navigation.css';

const Navigation = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const isActive = (path) => location.pathname === path;

  return (
    <nav className="navigation">
      <button 
        className={`nav-button ${isActive('/') ? 'active' : ''}`}
        onClick={() => navigate('/')}
      >
        <FaHome />
        <span>Главная</span>
      </button>
      <button 
        className={`nav-button ${isActive('/profile') ? 'active' : ''}`}
        onClick={() => navigate('/profile')}
      >
        <FaUser />
        <span>Профиль</span>
      </button>
      <button 
        className={`nav-button ${isActive('/forum') ? 'active' : ''}`}
        onClick={() => navigate('/forum')}
      >
        <FaComments />
        <span>Форум</span>
      </button>
    </nav>
  );
};

export default Navigation; 