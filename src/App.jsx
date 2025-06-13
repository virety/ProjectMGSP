import React, { useState, useEffect } from 'react';
import './App.css';
import Header from './components/Header';
import HeaderCabinet from './components/HeaderCabinet';
import Services from './components/Services';
import Products from './components/Products';
import Hero from './components/Hero';
import ModalAuth from './components/ModalAuth';
import Cabinet from './components/Cabinet';
import BottomInfo from './components/BottomInfo';
import ModalExchangeRates from './components/ModalExchangeRates';
import ModalDepositCalculator from './components/ModalDepositCalculator';
import ModalMap from './components/ModalMap';
import AssistantChat from './components/AssistantChat';

function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [activeScreen, setActiveScreen] = useState('main');
  const [showModal, setShowModal] = useState(false);
  const [authTab, setAuthTab] = useState("login");
  const [showExchangeRates, setShowExchangeRates] = useState(false);
  const [showDepositCalculator, setShowDepositCalculator] = useState(false);
  const [showMap, setShowMap] = useState(false);

  // Обработчик плавной прокрутки с отступом
  useEffect(() => {
    const handleAnchorClick = (e) => {
      const target = e.target || e.currentTarget;
      const anchor = target.closest('a[href^="#"]');
      if (!anchor) return;
      
      e.preventDefault();
      const targetId = anchor.getAttribute('href').slice(1);
      const targetElement = document.getElementById(targetId);
      
      if (targetElement) {
        const offset = 250;
        const elementPosition = targetElement.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - offset;
        
        window.scrollTo({
          top: offsetPosition,
          behavior: 'smooth'
        });
      }
    };

    document.addEventListener('click', handleAnchorClick);
    return () => document.removeEventListener('click', handleAnchorClick);
  }, []);

  // Проверяем авторизацию и загружаем данные пользователя при загрузке
  useEffect(() => {
    const isAuth = localStorage.getItem('isAuthenticated');
    if (isAuth === 'true') {
      setIsLoggedIn(true);
      // Загружаем данные пользователя
      const savedUserData = localStorage.getItem('userData');
      if (savedUserData) {
        const userData = JSON.parse(savedUserData);
        window.userData = userData;
      }
    }
  }, []);

  const handleLogin = () => {
    localStorage.setItem('isAuthenticated', 'true');
    setIsLoggedIn(true);
    setShowModal(false);
  };

  const handleLogout = () => {
    localStorage.removeItem('isAuthenticated');
    localStorage.removeItem('userData');
    localStorage.removeItem('userAvatar');
    setIsLoggedIn(false);
    setActiveScreen('main');
    window.userData = null;
  };

  const handleScreenChange = (screen) => {
    setActiveScreen(screen);
  };

  // Если пользователь авторизован, показываем личный кабинет
  if (isLoggedIn) {
    return (
      <>
        <HeaderCabinet 
          onLogout={handleLogout} 
          activeScreen={activeScreen}
          onScreenChange={handleScreenChange}
        />
        <Cabinet 
          onLogout={handleLogout}
          activeScreen={activeScreen}
        />
        <AssistantChat />
      </>
    );
  }

  // Если пользователь не авторизован, показываем главный экран
  return (
    <>
      <div className="app-background">
        <Header 
          isCabinet={isLoggedIn} 
          onCabinetClick={() => {
            setAuthTab("login"); 
            setShowModal(true);
          }}
          onLogout={handleLogout} 
        />
        <Hero
          onRegisterClick={() => { 
            setAuthTab("register"); 
            setShowModal(true); 
          }}
        />
          <main>
          <Services 
            onShowExchangeRates={() => setShowExchangeRates(true)}
            onShowDepositCalculator={() => setShowDepositCalculator(true)}
            onShowMap={() => setShowMap(true)}
          />
          <div className="cosmic-divider"></div>
          <Products />
          </main>
          <BottomInfo />
      </div>

      {/* Модальные окна на верхнем уровне */}
      <ModalAuth 
        show={showModal} 
        onClose={() => setShowModal(false)} 
        onSuccess={handleLogin}
        tab={authTab} 
        setTab={setAuthTab} 
      />
      <ModalExchangeRates 
        show={showExchangeRates}
        onClose={() => setShowExchangeRates(false)}
      />
      <ModalDepositCalculator
        show={showDepositCalculator}
        onClose={() => setShowDepositCalculator(false)}
      />
      <ModalMap
        show={showMap}
        onClose={() => setShowMap(false)}
      />
    </>
  );
}

export default App; 