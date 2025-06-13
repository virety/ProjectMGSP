import React from 'react';
import './ModalCryptoReceive.css';
import { FaTimes, FaQrcode, FaRegCopy } from 'react-icons/fa';

const ModalCryptoReceive = ({ show, onClose, asset }) => {
  if (!show || !asset) {
    return null;
  }
  
  // Mock address for demonstration
  const walletAddress = {
    BTC: '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
    ETH: '0x32Be343B94f860124dC4fEe278FDCBD38C102D88',
    BNB: 'bnb136ns6lfw4s5gabc8a2h2kh4fele4yccn2aa6x7'
  }[asset.ticker];

  const handleCopy = () => {
    navigator.clipboard.writeText(walletAddress);
    // You can add a notification here
  };

  return (
    <div className="modal-receive-overlay" onClick={onClose}>
      <div className="modal-receive" onClick={e => e.stopPropagation()}>
        <button className="modal-receive-close" onClick={onClose}>
          <FaTimes />
        </button>
        <h2 className="modal-receive-title">Получить {asset.name}</h2>
        
        <div className="qr-code-container">
          <FaQrcode className="qr-code-icon" />
          <p>Отсканируйте код или скопируйте адрес</p>
        </div>

        <div className="wallet-address-container">
          <span className="address-label">Адрес вашего кошелька</span>
          <div className="address-wrapper">
            <input type="text" readOnly value={walletAddress} />
            <button onClick={handleCopy}>
              <FaRegCopy />
            </button>
          </div>
        </div>

      </div>
    </div>
  );
};

export default ModalCryptoReceive; 