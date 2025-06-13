import React from 'react';
import './ModalCardRequisites.css';
import { FaTimes, FaRegCopy } from 'react-icons/fa';

const ModalCardRequisites = ({ show, onClose, cardDetails }) => {
  if (!show || !cardDetails) {
    return null;
  }

  const handleCopy = (text) => {
    navigator.clipboard.writeText(text).then(() => {
      // Maybe show a small notification/tooltip in the future
      console.log('Copied to clipboard:', text);
    });
  };

  // A mock full card number and CVV for demonstration
  const fullCardDetails = {
    ...cardDetails,
    fullNumber: `4500 1234 5678 ${cardDetails.number.slice(-4)}`,
    cvv: '123' 
  };

  return (
    <div className="modal-requisites-overlay" onClick={onClose}>
      <div className="modal-requisites" onClick={e => e.stopPropagation()}>
        <button className="modal-requisites-close" onClick={onClose}>
          <FaTimes />
        </button>
        <h2 className="modal-requisites-title">Реквизиты карты</h2>
        <p className="modal-requisites-card-name">{fullCardDetails.name}</p>

        <div className="requisites-grid">
          <div className="requisite-item">
            <span className="requisite-label">Номер карты</span>
            <div className="requisite-value-wrapper">
              <span className="requisite-value">{fullCardDetails.fullNumber}</span>
              <button className="copy-btn" onClick={() => handleCopy(fullCardDetails.fullNumber)}>
                <FaRegCopy />
              </button>
            </div>
          </div>
          <div className="requisite-item">
            <span className="requisite-label">Действует до</span>
            <div className="requisite-value-wrapper">
              <span className="requisite-value">{fullCardDetails.expiryDate}</span>
               <button className="copy-btn" onClick={() => handleCopy(fullCardDetails.expiryDate)}>
                <FaRegCopy />
              </button>
            </div>
          </div>
          <div className="requisite-item">
            <span className="requisite-label">CVV/CVC</span>
             <div className="requisite-value-wrapper">
              <span className="requisite-value">{fullCardDetails.cvv}</span>
               <button className="copy-btn" onClick={() => handleCopy(fullCardDetails.cvv)}>
                <FaRegCopy />
              </button>
            </div>
          </div>
           <div className="requisite-item">
            <span className="requisite-label">Владелец</span>
             <div className="requisite-value-wrapper">
              <span className="requisite-value">ANNA IVANOVA</span>
               <button className="copy-btn" onClick={() => handleCopy('ANNA IVANOVA')}>
                <FaRegCopy />
              </button>
            </div>
          </div>
        </div>

        <button className="modal-requisites-done-btn" onClick={onClose}>
          Готово
        </button>
      </div>
    </div>
  );
};

export default ModalCardRequisites; 