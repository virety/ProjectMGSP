import React, { useState, useEffect } from 'react';
import { FaTimes, FaChartLine, FaFilter } from 'react-icons/fa';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js';
import './ModalExchangeRates.css';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

const ModalExchangeRates = ({ show, onClose }) => {
  const [selectedPeriod, setSelectedPeriod] = useState('week');
  const [selectedCurrency, setSelectedCurrency] = useState('USD');
  const [chartData, setChartData] = useState(null);

  const periods = [
    { id: 'day', label: 'День' },
    { id: 'week', label: 'Неделя' },
    { id: 'month', label: 'Месяц' },
    { id: 'year', label: 'Год' }
  ];

  const currencies = [
    { code: 'USD', name: 'Доллар США', change: '+0.5%', rate: 91.23 },
    { code: 'EUR', name: 'Евро', change: '-0.3%', rate: 98.45 },
    { code: 'CNY', name: 'Китайский юань', change: '+0.2%', rate: 12.67 },
    { code: 'GBP', name: 'Фунт стерлингов', change: '+0.1%', rate: 114.89 },
    { code: 'JPY', name: 'Японская иена', change: '-0.4%', rate: 0.61 }
  ];

  // Генерация данных для графика в зависимости от выбранного периода и валюты
  const generateChartData = () => {
    const currency = currencies.find(c => c.code === selectedCurrency);
    const baseRate = currency?.rate || 90;
    let labels = [];
    let data = [];
    
    switch(selectedPeriod) {
      case 'day':
        labels = Array.from({length: 24}, (_, i) => `${i}:00`);
        data = Array.from({length: 24}, () => baseRate + (Math.random() - 0.5) * 2);
        break;
      case 'week':
        labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
        data = Array.from({length: 7}, () => baseRate + (Math.random() - 0.5) * 3);
        break;
      case 'month':
        labels = Array.from({length: 30}, (_, i) => `${i + 1}`);
        data = Array.from({length: 30}, () => baseRate + (Math.random() - 0.5) * 5);
        break;
      case 'year':
        labels = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
        data = Array.from({length: 12}, () => baseRate + (Math.random() - 0.5) * 8);
        break;
    }

    return {
      labels,
      datasets: [
        {
          label: `Курс ${selectedCurrency}/RUB`,
          data: data,
          borderColor: '#6c74c9',
          backgroundColor: 'rgba(108, 116, 201, 0.2)',
          tension: 0.4,
          fill: true,
          pointRadius: 4,
          pointBackgroundColor: '#fff',
          pointBorderColor: '#6c74c9',
          pointHoverRadius: 6,
        }
      ]
    };
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top',
        labels: {
          color: '#fff',
          font: {
            size: 14
          }
        }
      },
      tooltip: {
        mode: 'index',
        intersect: false,
        backgroundColor: 'rgba(24, 17, 77, 0.9)',
        titleColor: '#fff',
        bodyColor: '#fff',
        borderColor: '#6c74c9',
        borderWidth: 1,
        padding: 12,
        displayColors: false,
        callbacks: {
          label: function(context) {
            return `${context.parsed.y.toFixed(2)} ₽`;
          }
        }
      }
    },
    scales: {
      x: {
        grid: {
          color: 'rgba(255, 255, 255, 0.1)',
        },
        ticks: {
          color: '#fff'
        }
      },
      y: {
        grid: {
          color: 'rgba(255, 255, 255, 0.1)',
        },
        ticks: {
          color: '#fff',
          callback: function(value) {
            return value.toFixed(2) + ' ₽';
          }
        }
      }
    },
    interaction: {
      mode: 'nearest',
      axis: 'x',
      intersect: false
    }
  };

  useEffect(() => {
    if (show) {
      setChartData(generateChartData());
    }
  }, [selectedPeriod, selectedCurrency, show]);

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
            {chartData && (
              <Line data={chartData} options={chartOptions} />
            )}
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