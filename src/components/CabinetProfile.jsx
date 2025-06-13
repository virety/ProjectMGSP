import React, { useState, useEffect } from "react";
import "./CabinetProfile.css";
import {
  FaCog,
  FaUserCircle,
  FaUserEdit,
  FaShieldAlt,
  FaChevronDown,
  FaChevronUp,
  FaPiggyBank,
  FaCreditCard,
  FaHome,
  FaMoneyBillWave,
  FaUserAlt,
  FaLock
} from "react-icons/fa";
import { RiUser3Fill } from 'react-icons/ri';
import ModalProfileAvatar from './ModalProfileAvatar';
import ModalProfileName from './ModalProfileName';
import ModalProfileSecurity from './ModalProfileSecurity';

export const defaultAvatar = (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="100%" height="100%">
    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"/>
  </svg>
);

const USER_DATA = {
  firstName: "Анна",
  lastName: "Иванова",
  products: {
    deposits: [
      {
        type: "Вклад",
        name: "Накопительный",
        balance: "500 000 ₽",
        rate: "8.5%",
        endDate: "01.12.2024"
      }
    ],
    credits: [
      {
        type: "Кредит",
        name: "Потребительский",
        balance: "300 000 ₽",
        rate: "12.9%",
        monthlyPayment: "15 000 ₽",
        nextPayment: "25.04.2024"
      }
    ],
    mortgages: [
      {
        type: "Ипотека",
        name: "Квартира",
        balance: "5 000 000 ₽",
        rate: "7.9%",
        monthlyPayment: "45 000 ₽",
        nextPayment: "30.04.2024"
      }
    ]
  }
};

const CabinetProfile = () => {
  const [showSettings, setShowSettings] = useState(false);
  const [showAvatarModal, setShowAvatarModal] = useState(false);
  const [showNameModal, setShowNameModal] = useState(false);
  const [showSecurityModal, setShowSecurityModal] = useState(false);
  const [avatar, setAvatar] = useState(() => {
    const savedAvatar = localStorage.getItem('userAvatar');
    return savedAvatar || null;
  });
  const [firstName, setFirstName] = useState(() => {
    const savedUserData = localStorage.getItem('userData');
    if (savedUserData) {
      const userData = JSON.parse(savedUserData);
      return userData.firstName || 'Анна';
    }
    return 'Анна';
  });
  const [lastName, setLastName] = useState(() => {
    const savedUserData = localStorage.getItem('userData');
    if (savedUserData) {
      const userData = JSON.parse(savedUserData);
      return userData.lastName || 'Иванова';
    }
    return 'Иванова';
  });

  // Export user data for other components
  useEffect(() => {
    const userData = {
      firstName,
      lastName,
      avatar,
    };
    window.userData = userData;
    localStorage.setItem('userData', JSON.stringify(userData));
  }, [firstName, lastName, avatar]);

  const handleAvatarSave = (file) => {
    const reader = new FileReader();
    reader.onloadend = () => {
      const avatarDataUrl = reader.result;
      setAvatar(avatarDataUrl);
      localStorage.setItem('userAvatar', avatarDataUrl);
    };
    reader.readAsDataURL(file);
  };

  const handleNameSave = ({ firstName: newFirstName, lastName: newLastName }) => {
    setFirstName(newFirstName);
    setLastName(newLastName);
  };

  const handleSecuritySave = ({ currentPassword, newPassword }) => {
    // Here you would typically make an API call to update the password
    console.log('Password updated');
  };

  const renderProductCard = (product) => {
    const getIcon = (type) => {
      switch (type) {
        case "Вклад":
          return <FaPiggyBank />;
        case "Кредит":
          return <FaMoneyBillWave />;
        case "Ипотека":
          return <FaHome />;
        default:
          return <FaCreditCard />;
      }
    };

    return (
      <div className="profile-product-card" key={product.name}>
        <div className="profile-product-header">
          <div className="profile-product-icon">
            {getIcon(product.type)}
          </div>
          <div className="profile-product-title">{product.name}</div>
        </div>
        <div className="profile-product-details">
          <div className="profile-product-detail">
            <span className="detail-label">Остаток</span>
            <span className="detail-value">{product.balance}</span>
          </div>
          <div className="profile-product-detail">
            <span className="detail-label">Ставка</span>
            <span className="detail-value">{product.rate}</span>
          </div>
          {product.monthlyPayment && (
            <div className="profile-product-detail">
              <span className="detail-label">Ежемесячный платеж</span>
              <span className="detail-value">{product.monthlyPayment}</span>
            </div>
          )}
          {product.nextPayment && (
            <div className="profile-product-detail">
              <span className="detail-label">Следующий платеж</span>
              <span className="detail-value">{product.nextPayment}</span>
            </div>
          )}
          {product.endDate && (
            <div className="profile-product-detail">
              <span className="detail-label">Дата окончания</span>
              <span className="detail-value">{product.endDate}</span>
            </div>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="cabinet">
      <div className="cabinet-layout">
        <aside className="profile-sidebar">
          <div className="settings-menu">
            <button onClick={() => setShowAvatarModal(true)}>
              <FaUserCircle />
              <span>Аватар</span>
            </button>
            <button onClick={() => setShowNameModal(true)}>
              <FaUserAlt />
              <span>Имя</span>
            </button>
            <button onClick={() => setShowSecurityModal(true)}>
              <FaLock />
              <span>Безопасность</span>
            </button>
          </div>
        </aside>

        <main className="cabinet-main">
          <div className="profile-header">
            <div className="avatar">
              {avatar ? (
                <img src={avatar} alt="Profile" />
              ) : (
                defaultAvatar
              )}
            </div>
            <div className="profile-info">
              <h1 className="profile-name">{`${firstName} ${lastName}`}</h1>
            </div>
          </div>

          <div className="profile-products">
            {USER_DATA.products.deposits.map(renderProductCard)}
            {USER_DATA.products.credits.map(renderProductCard)}
            {USER_DATA.products.mortgages.map(renderProductCard)}
          </div>
        </main>

        <ModalProfileAvatar
          show={showAvatarModal}
          onClose={() => setShowAvatarModal(false)}
          onSave={handleAvatarSave}
        />

        <ModalProfileName
          show={showNameModal}
          onClose={() => setShowNameModal(false)}
          onSave={handleNameSave}
          currentFirstName={firstName}
          currentLastName={lastName}
        />

        <ModalProfileSecurity
          show={showSecurityModal}
          onClose={() => setShowSecurityModal(false)}
          onSave={handleSecuritySave}
        />
      </div>
    </div>
  );
};

export default CabinetProfile; 