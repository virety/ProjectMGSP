import React, { useState, useRef, useEffect } from 'react';
import { FaTimes, FaSearch } from 'react-icons/fa';
import './ModalTransactionHistory.css';

const ModalTransactionHistory = ({ show, onClose, transactions = [] }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [visibleTransactions, setVisibleTransactions] = useState([]);
  const [activeTab, setActiveTab] = useState('all'); // 'all', 'expense', 'income'

  const filterTransactions = (query, tab) => {
    let filtered = transactions;

    // Фильтрация по типу операции
    if (tab === 'expense') {
      filtered = filtered.filter(t => t.type === 'expense');
    } else if (tab === 'income') {
      filtered = filtered.filter(t => t.type === 'income');
    }

    if (!query.trim()) return filtered;

    const searchTerms = query.toLowerCase().split(' ').filter(term => term);
    
    return filtered.filter(transaction => {
      const isIncome = transaction.type === 'income';
      const amountString = `${isIncome ? '+' : '-'}${transaction.amount.toLocaleString('ru-RU')} ₽`;
      const searchableText = [
        transaction.title.toLowerCase(),
        transaction.date.toLowerCase(),
        amountString,
        isIncome ? 'доход поступление' : 'расход списание'
      ].join(' ');

      return searchTerms.every(term => {
        // Поиск по сумме (с учетом или без знака валюты и разделителей)
        if (term.match(/^[+-]?\d+/)) {
          const numericTerm = term.replace(/[^0-9+-]/g, '');
          const transactionAmount = amountString.replace(/[^0-9+-]/g, '');
          return transactionAmount.includes(numericTerm);
        }

        // Поиск по датам в разных форматах
        if (term.match(/^\d{1,2}\.\d{1,2}(\.\d{2,4})?$/)) {
          return transaction.date.includes(term);
        }

        // Поиск по типу транзакции
        if (term === 'доход' || term === 'поступление') {
          return isIncome;
        }
        if (term === 'расход' || term === 'списание') {
          return !isIncome;
        }

        // Поиск по названию и общей информации
        return searchableText.includes(term);
      });
    });
  };

  useEffect(() => {
    const filteredResults = filterTransactions(searchQuery, activeTab);
    setVisibleTransactions(filteredResults);
  }, [searchQuery, activeTab, show, transactions]);

  if (!show) return null;

  return (
    <div className="modal-history-overlay" onClick={onClose}>
      <div className="modal-history" onClick={e => e.stopPropagation()}>
        <button className="modal-history-close" onClick={onClose}>
          <FaTimes />
        </button>

        <h2 className="modal-history-title">История операций</h2>

        <div className="modal-history-tabs">
          <button 
            className={`modal-history-tab ${activeTab === 'all' ? 'active' : ''}`}
            onClick={() => setActiveTab('all')}
          >
            Все операции
          </button>
          <button 
            className={`modal-history-tab ${activeTab === 'expense' ? 'active' : ''}`}
            onClick={() => setActiveTab('expense')}
          >
            Траты
          </button>
          <button 
            className={`modal-history-tab ${activeTab === 'income' ? 'active' : ''}`}
            onClick={() => setActiveTab('income')}
          >
            Пополнения
          </button>
        </div>

        <div className="modal-history-search">
          <FaSearch className="modal-history-search-icon" />
          <input
            type="text"
            placeholder="Поиск по названию, дате или сумме..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="modal-history-content">
          {visibleTransactions.map((transaction) => (
            <div 
              key={transaction.id} 
              className="modal-history-item"
            >
              <div className="modal-history-item-info">
                <div className="modal-history-item-title">{transaction.title}</div>
                <div className="modal-history-item-date">{transaction.date}</div>
              </div>
              <div className={`modal-history-item-amount ${transaction.type}`}>
                {transaction.type === 'income' ? '+' : '-'}{transaction.amount.toLocaleString('ru-RU')} ₽
              </div>
            </div>
          ))}
          {visibleTransactions.length === 0 && (
            <div className="modal-history-no-results">
              По вашему запросу ничего не найдено
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ModalTransactionHistory; 