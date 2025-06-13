import React from 'react';
import './ModalConfirmBlock.css';
import { FaTimes, FaExclamationTriangle } from 'react-icons/fa';

const ModalConfirmBlock = ({ show, onClose, onConfirm, cardName }) => {
  if (!show) {
    return null;
  }

  return (
    <div className="modal-confirm-overlay" onClick={onClose}>
      <div className="modal-confirm" onClick={e => e.stopPropagation()}>
        <button className="modal-confirm-close" onClick={onClose}>
          <FaTimes />
        </button>

        <div className="modal-confirm-header">
          <FaExclamationTriangle className="modal-confirm-icon" />
          <h2 className="modal-confirm-title">Подтверждение блокировки</h2>
        </div>

        <p className="modal-confirm-text">
          Вы уверены, что хотите заблокировать карту "{cardName}"?
          <br />
          Это действие необратимо через онлайн-банк.
        </p>

        <div className="modal-confirm-actions">
          <button
            className="modal-confirm-btn cancel"
            onClick={onClose}
          >
            Отмена
          </button>
          <button
            className="modal-confirm-btn confirm"
            onClick={onConfirm}
          >
            Заблокировать
          </button>
        </div>
      </div>
    </div>
  );
};

export default ModalConfirmBlock; 