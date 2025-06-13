import React, { useState, useEffect } from 'react';
import './ModalCryptoWallet.css';
import { FaTimes, FaBtc, FaEthereum } from 'react-icons/fa';
import { SiBinance } from "react-icons/si";
import ModalCryptoReceive from './ModalCryptoReceive';
import ModalCryptoSend from './ModalCryptoSend';

const initialAssets = [
  {
    name: 'Bitcoin',
    ticker: 'BTC',
    icon: <FaBtc />,
    balance: 0.5234,
    fiatBalance: 36150.52,
    color: '#F7931A'
  },
  {
    name: 'Ethereum',
    ticker: 'ETH',
    icon: <FaEthereum />,
    balance: 10.18,
    fiatBalance: 35120.88,
    color: '#627EEA'
  },
  {
    name: 'BNB',
    ticker: 'BNB',
    icon: <SiBinance />,
    balance: 25.71,
    fiatBalance: 15330.10,
    color: '#F0B90B'
  },
];

const ModalCryptoWallet = ({ show, onClose }) => {
  const [assets, setAssets] = useState(initialAssets);
  const [showReceive, setShowReceive] = useState(false);
  const [showSend, setShowSend] = useState(false);
  const [selectedAsset, setSelectedAsset] = useState(null);

  useEffect(() => {
    if (!show) {
      setShowReceive(false);
      setShowSend(false);
    }
  }, [show]);

  const totalBalance = assets.reduce((sum, asset) => sum + asset.fiatBalance, 0);

  const handleReceiveClick = () => {
    setSelectedAsset(assets[0]); // Default to first asset or implement selection
    setShowReceive(true);
  };
  
  const handleSendClick = () => {
    setShowSend(true);
  };
  
  const handleConfirmSend = (sendData) => {
    setAssets(prevAssets => {
      const newAssets = prevAssets.map(asset => {
        if (asset.ticker === sendData.ticker) {
          const newBalance = asset.balance - sendData.amount;
          // In a real app, fiat balance would be updated via an API call
          const newFiatBalance = asset.fiatBalance * (newBalance / asset.balance);
          return { ...asset, balance: newBalance, fiatBalance: newFiatBalance };
        }
        return asset;
      });
      return newAssets;
    });
  };

  if (!show) {
    return null;
  }

  return (
    <>
      <div className="modal-crypto-overlay" onClick={onClose}>
        <div className="modal-crypto" onClick={e => e.stopPropagation()}>
          <button className="modal-crypto-close" onClick={onClose}>
            <FaTimes />
          </button>
          
          <div className="modal-crypto-header">
            <h2 className="modal-crypto-title">Криптокошелек</h2>
            <div className="crypto-total-balance">
              <span className="balance-label">Общий баланс</span>
              <span className="balance-value">
                {totalBalance.toLocaleString('ru-RU', { style: 'currency', currency: 'USD' })}
              </span>
            </div>
          </div>

          <div className="crypto-assets-list">
            {assets.map(asset => (
              <div key={asset.ticker} className="crypto-asset-item">
                <div className="asset-icon" style={{ color: asset.color }}>
                  {asset.icon}
                </div>
                <div className="asset-info">
                  <span className="asset-name">{asset.name}</span>
                  <span className="asset-balance-crypto">{asset.balance} {asset.ticker}</span>
                </div>
                <div className="asset-fiat-balance">
                  {asset.fiatBalance.toLocaleString('ru-RU', { style: 'currency', currency: 'USD' })}
                </div>
              </div>
            ))}
          </div>

          <div className="modal-crypto-actions">
            <button className="crypto-action-btn receive" onClick={handleReceiveClick}>Получить</button>
            <button className="crypto-action-btn send" onClick={handleSendClick}>Отправить</button>
          </div>
        </div>
      </div>

      <ModalCryptoReceive 
        show={showReceive}
        onClose={() => setShowReceive(false)}
        asset={selectedAsset}
      />
      <ModalCryptoSend
        show={showSend}
        onClose={() => setShowSend(false)}
        assets={assets}
        onConfirm={handleConfirmSend}
      />
    </>
  );
};

export default ModalCryptoWallet; 