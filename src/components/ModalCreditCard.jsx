import React from "react";
import "./ModalCreditCard.css";

const ModalCreditCard = ({ show, onClose }) => {
  if (!show) return null;

  return (
    <div className="modal-creditcard-overlay" onClick={onClose}>
      <div className="modal-creditcard" onClick={e => e.stopPropagation()}>
        <button className="modal-creditcard-close" onClick={onClose}>×</button>
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
          <button className="modal-creditcard-activate">Активировать</button>
        </div>
      </div>
    </div>
  );
};

export default ModalCreditCard; 