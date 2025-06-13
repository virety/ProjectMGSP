import React from 'react';
import './ModalReceiveMoney.css';
import { FaTimes, FaQrcode, FaRegCopy } from 'react-icons/fa';

const ModalReceiveMoney = ({ show, onClose, card }) => {
  if (!show || !card) {
    return null;
  }

  // В реальном приложении здесь будет ссылка на пополнение счета
  const receiveLink = `https://example.com/pay?card=${card.number}`; 
  const cardDetailsText = `Номер карты: ${card.number}\nВладелец: ${card.holder}`;

  const handleCopy = () => {
    navigator.clipboard.writeText(cardDetailsText);
    alert('Реквизиты скопированы!');
  };

  return (
    <div className="modal-receive-money-overlay" onClick={onClose}>
      <div className="modal-receive-money" onClick={e => e.stopPropagation()}>
        <button className="modal-receive-money-close" onClick={onClose}>
          <FaTimes />
        </button>
        <h2 className="modal-receive-money-title">Получить перевод</h2>
        
        <div className="qr-code-container-money">
          {/* Здесь должен быть реальный QR-код, сгенерированный на основе receiveLink */}
          <FaQrcode className="qr-code-icon-money" />
          <p>Покажите этот QR-код отправителю</p>
        </div>

        <div className="card-details-container">
          <span className="details-label">Или скопируйте реквизиты</span>
          <div className="details-wrapper">
            <textarea readOnly value={cardDetailsText} rows={2} />
            <button onClick={handleCopy}>
              <FaRegCopy />
            </button>
          </div>
        </div>

      </div>
    </div>
  );
};

export default ModalReceiveMoney; 