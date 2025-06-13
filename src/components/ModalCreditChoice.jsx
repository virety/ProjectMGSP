import React, { useState } from "react";
import "./ModalCreditChoice.css";
import ModalCreditCard from "./ModalCreditCard";
import ModalConsumerLoan from "./ModalConsumerLoan";
import { FaTimes } from "react-icons/fa";

const ModalCreditChoice = ({ show, onClose }) => {
  const [showCreditCard, setShowCreditCard] = useState(false);
  const [showConsumerLoan, setShowConsumerLoan] = useState(false);

  // If any of the sub-modals are shown, don't show the choice modal
  if (showCreditCard) {
    return (
      <ModalCreditCard 
        show={true} 
        onClose={() => {
          setShowCreditCard(false);
          onClose();
        }} 
      />
    );
  }

  if (showConsumerLoan) {
    return (
      <ModalConsumerLoan 
        show={true} 
        onClose={() => {
          setShowConsumerLoan(false);
          onClose();
        }} 
      />
    );
  }

  if (!show) return null;

  return (
    <div className="modal-creditchoice-overlay" onClick={onClose}>
      <div className="modal-creditchoice" onClick={e => e.stopPropagation()}>
        <button className="modal-creditchoice-close" onClick={onClose}><FaTimes /></button>
        <div className="modal-creditchoice-title">Выберите тип кредита</div>
        <div className="modal-creditchoice-options">
          <div 
            className="modal-creditchoice-option"
            onClick={() => setShowCreditCard(true)}
          >
            <div className="modal-creditchoice-option-icon">💳</div>
            <div className="modal-creditchoice-option-content">
              <div className="modal-creditchoice-option-title">Кредитная карта</div>
              <div className="modal-creditchoice-option-description">
                Кредитный лимит до 500 000 ₽, льготный период до 120 дней
              </div>
            </div>
          </div>
          <div 
            className="modal-creditchoice-option"
            onClick={() => setShowConsumerLoan(true)}
          >
            <div className="modal-creditchoice-option-icon">💰</div>
            <div className="modal-creditchoice-option-content">
              <div className="modal-creditchoice-option-title">Потребительский кредит</div>
              <div className="modal-creditchoice-option-description">
                Сумма до 5 000 000 ₽, срок до 60 месяцев
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ModalCreditChoice; 