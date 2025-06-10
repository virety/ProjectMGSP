import React from "react";
import "./ModalCardDetails.css";

const ModalCardDetails = ({ show, onClose, card }) => {
  if (!show) return null;
  return (
    <div className="modal-carddetails-overlay" onClick={onClose}>
      <div className="modal-carddetails" onClick={e => e.stopPropagation()}>
        <div className="modal-carddetails-title">Ваша карта</div>
        <div className="modal-carddetails-card" style={{ background: card.color }}>
          <div className="modal-carddetails-chip"></div>
          <div className="modal-carddetails-number">{card.number}</div>
          <div className="modal-carddetails-valid">VALID THRU: {card.expiryDate}</div>
          <div className="modal-carddetails-balance">Баланс: {card.balance}</div>
        </div>
        <div className="modal-carddetails-actions">
          <button>Пополнить</button>
          <button>Показать реквизиты</button>
          <button>Заблокировать</button>
        </div>
        <button className="modal-carddetails-close" onClick={onClose}>Закрыть</button>
        <div className="modal-carddetails-bg"></div>
      </div>
    </div>
  );
};

export default ModalCardDetails; 