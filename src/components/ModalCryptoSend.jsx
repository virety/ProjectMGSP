import React, { useState, useEffect } from 'react';
import './ModalCryptoSend.css';
import { FaTimes } from 'react-icons/fa';

const ModalCryptoSend = ({ show, onClose, assets, onConfirm }) => {
  const [selectedAsset, setSelectedAsset] = useState(null);
  const [address, setAddress] = useState('');
  const [amount, setAmount] = useState('');

  useEffect(() => {
    if (assets && assets.length > 0) {
      setSelectedAsset(assets[0]);
    }
  }, [assets]);

  if (!show) {
    return null;
  }

  const handleAssetChange = (e) => {
    const asset = assets.find(a => a.ticker === e.target.value);
    setSelectedAsset(asset);
    setAmount(''); // Reset amount when asset changes
  };

  const handleSend = () => {
    if (!address || !amount) {
      alert('Пожалуйста, введите адрес и сумму.');
      return;
    }
    const numericAmount = parseFloat(amount);
    if (numericAmount <= 0) {
      alert('Сумма должна быть положительной.');
      return;
    }
    if (numericAmount > selectedAsset.balance) {
      alert('Недостаточно средств.');
      return;
    }
    
    // Call the passed onConfirm function from the parent
    onConfirm({
      ticker: selectedAsset.ticker,
      amount: numericAmount,
      address: address
    });
    
    alert(`Вы успешно инициировали отправку ${amount} ${selectedAsset.ticker}!`);
    onClose();
  };
  
  const balance = selectedAsset ? selectedAsset.balance : 0;

  return (
    <div className="modal-send-overlay" onClick={onClose}>
      <div className="modal-send" onClick={e => e.stopPropagation()}>
        <button className="modal-send-close" onClick={onClose}>
          <FaTimes />
        </button>
        <h2 className="modal-send-title">Отправить криптовалюту</h2>

        <div className="send-form">
          <div className="form-group">
            <label htmlFor="asset-select">Актив</label>
            <select id="asset-select" onChange={handleAssetChange} value={selectedAsset ? selectedAsset.ticker : ''}>
              {assets.map(asset => (
                <option key={asset.ticker} value={asset.ticker}>
                  {asset.name}
                </option>
              ))}
            </select>
          </div>

          {selectedAsset && (
            <>
              <p className="modal-send-balance">Баланс: {balance.toFixed(6)} {selectedAsset.ticker}</p>
              <div className="form-group">
                <label htmlFor="address">Адрес получателя</label>
                <input
                  type="text"
                  id="address"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder={`Введите адрес кошелька ${selectedAsset.ticker}`}
                />
              </div>
              <div className="form-group">
                <label htmlFor="amount">Сумма</label>
                <div className="amount-input-wrapper">
                  <input
                    type="number"
                    id="amount"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="0.00"
                  />
                  <button className="max-button" onClick={() => setAmount(balance.toString())}>MAX</button>
                </div>
              </div>
            </>
          )}
        </div>

        <button className="send-button" onClick={handleSend} disabled={!selectedAsset}>
          Отправить
        </button>
      </div>
    </div>
  );
};

export default ModalCryptoSend; 