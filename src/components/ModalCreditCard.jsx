import React, { useState } from "react";
import "./ModalCreditCard.css";
import { FaTimes } from "react-icons/fa";

const ModalCreditCard = ({ show, onClose }) => {
  const [showSuccess, setShowSuccess] = useState(false);

  if (!show) return null;

  if (showSuccess) {
    return (
      <div className="modal-creditcard-overlay">
        <div className="modal-creditcard">
          <button className="modal-creditcard-close" onClick={onClose}><FaTimes /></button>
          <div className="modal-creditcard-title">Заявка принята!</div>
          <p className="modal-creditcard-success-text">
            Ваша заявка на кредитную карту принята в обработку.
            Мы рассмотрим её в ближайшее время и сообщим о решении.
          </p>
          <button className="modal-creditcard-submit" onClick={onClose}>
            Закрыть
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="modal-creditcard-overlay" onClick={onClose}>
      <div className="modal-creditcard" onClick={e => e.stopPropagation()}>
        <button className="modal-creditcard-close" onClick={onClose}><FaTimes /></button>
        <div className="modal-creditcard-title">Кредитная карта</div>
        <div className="modal-creditcard-content">
          <div className="modal-creditcard-features">
            <div className="modal-creditcard-feature">
              <span className="modal-creditcard-feature-title">Кредитный лимит</span>
              <span className="modal-creditcard-feature-value">до 500 000 ₽</span>
            </div>
            <div className="modal-creditcard-feature">
              <span className="modal-creditcard-feature-title">Процентная ставка</span>
              <span className="modal-creditcard-feature-value">от 19,9% годовых</span>
            </div>
            <div className="modal-creditcard-feature">
              <span className="modal-creditcard-feature-title">Льготный период</span>
              <span className="modal-creditcard-feature-value">до 120 дней</span>
            </div>
            <div className="modal-creditcard-feature">
              <span className="modal-creditcard-feature-title">Стоимость обслуживания</span>
              <span className="modal-creditcard-feature-value">0 ₽ в год</span>
            </div>
          </div>
          <button className="modal-creditcard-submit" onClick={() => setShowSuccess(true)}>
            Активировать
          </button>
        </div>
      </div>
    </div>
  );
};

export default ModalCreditCard; 