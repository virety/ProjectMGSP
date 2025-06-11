import React, { useState } from 'react';
import { FaTimes, FaChartLine, FaFilter } from 'react-icons/fa';
import './ModalExchangeRates.css';

const ModalExchangeRates = ({ show, onClose }) => {
  const [selectedPeriod, setSelectedPeriod] = useState('week');
  const [selectedCurrency, setSelectedCurrency] = useState('USD');

  const periods = [
    { id: 'day', label: 'День' },
    { id: 'week', label: 'Неделя' },
    { id: 'month', label: 'Месяц' },
    { id: 'year', label: 'Год' }
  ];

  const currencies = [
    { code: 'USD', name: 'Доллар США', change: '+0.5%' },
    { code: 'EUR', name: 'Евро', change: '-0.3%' },
    { code: 'CNY', name: 'Китайский юань', change: '+0.2%' },
    { code: 'GBP', name: 'Фунт стерлингов', change: '+0.1%' },
    { code: 'JPY', name: 'Японская иена', change: '-0.4%' }
  ];

  if (!show) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content exchange-rates-modal" onClick={e => e.stopPropagation()}>
        <button className="modal-close" onClick={onClose}>
          <FaTimes />
        </button>
        
        <div className="exchange-rates-header">
          <h2>Курсы валют</h2>
          <div className="exchange-rates-filters">
            <div className="period-filter">
              {periods.map(period => (
                <button
                  key={period.id}
                  className={`period-button ${selectedPeriod === period.id ? 'active' : ''}`}
                  onClick={() => setSelectedPeriod(period.id)}
                >
                  {period.label}
                </button>
              ))}
            </div>
          </div>
        </div>

        <div className="exchange-rates-content">
          <div className="exchange-rates-graph">
            <div className="graph-placeholder">
              <FaChartLine className="graph-icon" />
              <p>График курса {selectedCurrency}</p>
              <span>Здесь будет отображаться график курса валюты</span>
            </div>
          </div>

          <div className="exchange-rates-sidebar">
            <div className="top-currencies">
              <h3>Топ валют</h3>
              {currencies.map(currency => (
                <div 
                  key={currency.code}
                  className={`currency-item ${selectedCurrency === currency.code ? 'active' : ''}`}
                  onClick={() => setSelectedCurrency(currency.code)}
                >
                  <div className="currency-info">
                    <span className="currency-code">{currency.code}</span>
                    <span className="currency-name">{currency.name}</span>
                  </div>
                  <span className={`currency-change ${currency.change.startsWith('+') ? 'positive' : 'negative'}`}>
                    {currency.change}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ModalExchangeRates; 