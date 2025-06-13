import React, { useState, useEffect, useRef } from "react";
import "./ModalCardDetails.css";
import { FaCreditCard, FaTimes, FaRedo, FaQrcode, FaReceipt, FaShieldAlt } from 'react-icons/fa';
import ModalReceiveMoney from './ModalReceiveMoney';

const ModalCardDetails = ({ show, onClose, cardDetails, onBlock, onRequisites, cardBgUrl, onBgChange }) => {
  const [isFlipped, setIsFlipped] = useState(false);
  const [showReceive, setShowReceive] = useState(false);
  const fileInputRef = useRef(null);

  useEffect(() => {
    if(show) {
        setIsFlipped(false);
        setShowReceive(false);
    }
  }, [show]);

  const handleBgChangeClick = (e) => {
    e.stopPropagation();
    fileInputRef.current.click();
  };

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file && file.type.startsWith("image/")) {
      const reader = new FileReader();
      reader.onload = (event) => {
        const imageDataUrl = event.target.result;
        onBgChange(cardDetails.id, imageDataUrl);
      };
      reader.readAsDataURL(file);
    }
  };

  if (!show || !cardDetails) return null;

  const isBlocked = cardDetails.isBlocked;

  return (
    <>
      <div className="modal-carddetails-overlay" onClick={onClose}>
        <div className="modal-carddetails" onClick={e => e.stopPropagation()}>
          
          <input
            type="file"
            ref={fileInputRef}
            onChange={handleFileChange}
            style={{ display: "none" }}
            accept="image/*"
          />

          <div className="scene">
            <div className={`card ${isFlipped ? 'is-flipped' : ''}`} onClick={() => setIsFlipped(!isFlipped)}>
              <div className="card__face card__face--front" style={{ backgroundImage: `url(${cardBgUrl})` }}>
                <div className="card-header">
                  <span className="card-bank-name">NB</span>
                  <FaCreditCard className="card-type-icon" />
                </div>
                <div className="card-chip" />
                <div className="card-number">{cardDetails.number}</div>
                <div className="card-footer">
                  <div className="card-holder">
                    <span className="card-label">Владелец</span>
                    <span>АННА ИВАНОВА</span>
                  </div>
                  <div className="card-expiry">
                    <span className="card-label">Срок</span>
                    <span>{cardDetails.expiryDate}</span>
                  </div>
                </div>
              </div>
              <div className="card__face card__face--back" style={{ backgroundImage: `url(${cardBgUrl})` }}>
                <div className="card-mag-stripe" />
                <div className="card-sig-cvv-line">
                  <div className="card-signature-box">
                    <span className="card-sig-label">Подпись</span>
                  </div>
                  <div className="card-cvv">
                    <span className="card-label">CVV</span>
                    <span>123</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <div className="modal-carddetails-info">
              <div className="info-balance">
                <span className="balance-label">Баланс</span>
                <span className="balance-value">{cardDetails.balance.toLocaleString('ru-RU', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} <span className="currency">{cardDetails.currency}</span></span>
              </div>
              <button className="change-bg-btn" onClick={handleBgChangeClick}>
                <FaRedo />
                <span>Сменить фон</span>
              </button>
          </div>

          <div className="modal-carddetails-actions">
            <button 
              className="card-action-btn" 
              disabled={isBlocked}
              onClick={() => setShowReceive(true)}
            >
              <FaQrcode />
              <span>Получить</span>
            </button>
            <button 
              className="card-action-btn" 
              disabled={isBlocked}
              onClick={() => onRequisites(cardDetails)}
            >
              <FaReceipt />
              <span>Реквизиты</span>
            </button>
            <button 
              className="card-action-btn danger" 
              onClick={() => onBlock(cardDetails)}
              disabled={isBlocked}
            >
              <FaShieldAlt />
              <span>{isBlocked ? 'Заблокирована' : 'Блокировать'}</span>
            </button>
          </div>
          
          <button className="modal-carddetails-close" onClick={onClose}>
            <FaTimes />
          </button>

        </div>
      </div>

      <ModalReceiveMoney 
          show={showReceive}
          onClose={() => setShowReceive(false)}
          card={cardDetails}
      />
    </>
  );
};

export default ModalCardDetails; 