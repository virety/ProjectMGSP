import React, { useState, useEffect } from "react";
import "./Cabinet.css";
import ModalNewProduct from "./ModalNewProduct";
import ModalCardDetails from "./ModalCardDetails";
import ModalTransactionHistory from "./ModalTransactionHistory";
import ModalTransfer from "./ModalTransfer";
import ModalMap from "./ModalMap";
import ModalExchangeRates from "./ModalExchangeRates";
import CabinetProfile from "./CabinetProfile";
import CabinetForum from "./CabinetForum";
import { FaSignOutAlt, FaExchangeAlt, FaMobileAlt, FaMoneyBill, FaCreditCard, FaEllipsisH, FaChartLine, FaBitcoin } from "react-icons/fa";
import ModalConfirmBlock from "./ModalConfirmBlock";
import ModalCardRequisites from "./ModalCardRequisites";
import ModalTopUp from "./ModalTopUp";
import ModalCryptoWallet from "./ModalCryptoWallet";

// Import default backgrounds
import bg1 from '../images/card-bg-1.png';
import bg2 from '../images/card-bg-2.png';
import bg3 from '../images/card-bg-3.png';
import bg4 from '../images/card-bg-4.png';

const defaultCardBgs = [bg1, bg2, bg3, bg4];

const USER_NAME = "Анна";

const cards = [
  {
    id: 'card-1',
    type: "Основная карта",
    name: "Основная карта",
    number: "**** 1234",
    balance: 353.45,
    currency: "RUB",
    iconComponent: FaCreditCard,
    color: "linear-gradient(135deg, #6c74c9 0%, #18114D 100%)",
    expiryDate: "12/25",
    isBlocked: false,
  },
  {
    id: 'card-2',
    type: "Зарплатная карта",
    name: "Зарплатная карта",
    number: "**** 5678",
    balance: 120500.00,
    currency: "RUB",
    iconComponent: FaCreditCard,
    color: "linear-gradient(135deg, #8b5cf6 0%, #4c1d95 100%)",
    expiryDate: "08/26",
    isBlocked: false,
  }
];

const actions = [
  { label: "Открыть накопительный счет" }
];

const quickActions = [
  { iconComponent: FaExchangeAlt, label: "Перевести" },
  { iconComponent: FaBitcoin, label: "Крипто" },
  { iconComponent: FaMoneyBill, label: "Снять наличные" },
  { iconComponent: FaChartLine, label: "Курсы валют" }
];

const categoryColors = {
  "Переводы": "#ff8a8a",
  "Супермаркеты": "#8b5cf6",
  "Рестораны": "#a5b4fc",
  "Такси": "#524CA1",
  "Маркетплейсы": "#b2b2d6",
  "Коммунальные": "#fca5a5",
  "Остальное": "#d4bdea",
  "Поступления": "#6c74c9",
  "Зарплата": "#a55eea",
  "Кэшбек": "#c878e8",
  "Проценты": "#e7a3f5",
  "Другое": "#f3d9fa",
};

const initialTransactions = [
  { id: 1, title: "Поступление от Ивана", amount: 15000, date: "Сегодня, 14:30", type: "income", category: "Поступления" },
  { id: 2, title: "Пятёрочка", amount: 2450, date: "Сегодня, 12:15", type: "expense", category: "Супермаркеты" },
  { id: 3, title: "Такси", amount: 350, date: "Вчера, 18:45", type: "expense", category: "Такси" },
  { id: 4, title: "Зарплата", amount: 75000, date: "10.07.2024", type: "income", category: "Зарплата" },
  { id: 5, title: "Яндекс.Маркет", amount: 5200, date: "09.07.2024", type: "expense", category: "Маркетплейсы" },
  { id: 6, title: "Ресторан 'Облака'", amount: 3200, date: "08.07.2024", type: "expense", category: "Рестораны" },
  { id: 7, title: "Кэшбек за Июль", amount: 1250, date: "05.07.2024", type: "income", category: "Кэшбек" },
];

function getGreeting(name) {
  const now = new Date();
  const h = now.getHours();
  const m = now.getMinutes();
  const time = h * 60 + m;
  if (time >= 0 && time <= 360) return `Доброй ночи, ${name}!`;
  if (time > 360 && time <= 720) return `Доброе утро, ${name}!`;
  if (time > 720 && time <= 1080) return `Добрый день, ${name}!`;
  return `Добрый вечер, ${name}!`;
}

const Cabinet = ({ onLogout, activeScreen = 'main' }) => {
  const [tab, setTab] = useState("traty");
  const [showModal, setShowModal] = useState(false);
  const [showCard, setShowCard] = useState(false);
  const [showHistory, setShowHistory] = useState(false);
  const [showTransfer, setShowTransfer] = useState(false);
  const [showMap, setShowMap] = useState(false);
  const [showExchangeRates, setShowExchangeRates] = useState(false);
  const [userCards, setUserCards] = useState(cards);
  const [recentTransactions, setRecentTransactions] = useState(initialTransactions);
  const [activeProducts, setActiveProducts] = useState([]);
  const [selectedCard, setSelectedCard] = useState(null);
  const [showConfirmBlock, setShowConfirmBlock] = useState(false);
  const [showRequisites, setShowRequisites] = useState(false);
  const [showTopUp, setShowTopUp] = useState(false);
  const [cardBgs, setCardBgs] = useState({});
  const [showCryptoWallet, setShowCryptoWallet] = useState(false);
  
  useEffect(() => {
    const loadedBgs = {};
    cards.forEach(card => {
      const customBg = localStorage.getItem(`cardCustomBg_${card.id}`);
      if (customBg) {
        loadedBgs[card.id] = customBg;
      } else {
        let savedDefaultIndex = localStorage.getItem(`cardDefaultBgIndex_${card.id}`);
        if (savedDefaultIndex === null) {
          savedDefaultIndex = Math.floor(Math.random() * defaultCardBgs.length);
          localStorage.setItem(`cardDefaultBgIndex_${card.id}`, savedDefaultIndex);
        }
        loadedBgs[card.id] = defaultCardBgs[parseInt(savedDefaultIndex, 10)];
      }
    });
    setCardBgs(loadedBgs);
  }, []);

  const handleCardBgChange = (cardId, bgDataUrl) => {
    localStorage.setItem(`cardCustomBg_${cardId}`, bgDataUrl);
    setCardBgs(prevBgs => ({ ...prevBgs, [cardId]: bgDataUrl }));
  };

  const handleBlockCardRequest = (card) => {
    setSelectedCard(card);
    setShowConfirmBlock(true);
  };

  const handleRequisitesRequest = (card) => {
    setSelectedCard(card);
    setShowRequisites(true);
  }

  const handleTopUpRequest = (card) => {
    setSelectedCard(card);
    setShowTopUp(true);
  };

  const handleConfirmBlock = () => {
    setUserCards(prevCards =>
      prevCards.map(card =>
        card.id === selectedCard.id ? { ...card, isBlocked: true } : card
      )
    );
    setShowConfirmBlock(false);
    setShowCard(false); // Close details modal after blocking
  };

  const handleConfirmTopUp = (amount) => {
    // Update card balance
    setUserCards(prevCards =>
      prevCards.map(card => {
        if (card.id === selectedCard.id) {
          return { ...card, balance: card.balance + amount };
        }
        return card;
      })
    );
    // Add transaction
    const newTransaction = {
      id: Date.now(),
      title: "Пополнение",
      amount: amount,
      date: new Date().toLocaleString('ru-RU', { day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' }),
      type: 'income',
      category: 'Поступления',
    };
    setRecentTransactions(prev => [newTransaction, ...prev]);
    setShowTopUp(false);
  };

  const handleMakeTransfer = (transferData) => {
    const { fromCardId, amount, recipient, comment } = transferData;
    const transferAmount = parseFloat(amount);

    // Update card balance
    const updatedCards = userCards.map(card => {
      if (card.id === fromCardId) {
        return { ...card, balance: card.balance - transferAmount };
      }
      return card;
    });
    setUserCards(updatedCards);

    // Add to transaction history
    const newTransaction = {
      id: Date.now(),
      title: `Перевод для ${recipient}`,
      amount: transferAmount,
      date: new Date().toLocaleString('ru-RU', { day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' }),
      type: 'expense',
      category: 'Переводы',
      comment: comment
    };
    setRecentTransactions(prev => [newTransaction, ...prev]);
  };

  const processTransactions = (type) => {
    const filtered = recentTransactions.filter(t => t.type === type);
    const grouped = filtered.reduce((acc, transaction) => {
      const { category, amount } = transaction;
      if (!acc[category]) {
        acc[category] = { label: category, value: 0, color: categoryColors[category] || '#ccc' };
      }
      acc[category].value += amount;
      return acc;
    }, {});
    return Object.values(grouped).sort((a, b) => b.value - a.value);
  };

  const dataMap = {
    traty: processTransactions('expense'),
    popoln: processTransactions('income'),
  };

  const currentData = dataMap[tab];
  const total = currentData.reduce((sum, op) => sum + op.value, 0);
  const pieLabel = tab === 'traty' ? 'Траты' : 'Пополнения';

  const handleProductActivation = (product) => {
    setActiveProducts(prev => [...prev, product]);
  };

  const handleQuickAction = (label) => {
    switch (label) {
      case "Перевести":
        setShowTransfer(true);
        break;
      case "Крипто":
        setShowCryptoWallet(true);
        break;
      case "Снять наличные":
        setShowMap(true);
        break;
      case "Курсы валют":
        setShowExchangeRates(true);
        break;
      default:
        break;
    }
  };

  const handleLogout = () => {
    setShowModal(false);
    setShowCard(false);
    setShowHistory(false);
    setShowTransfer(false);
    setShowMap(false);
    setShowExchangeRates(false);
    onLogout();
  };

  const handleCardClick = (card) => {
    setSelectedCard(card);
    setShowCard(true);
  };

  const renderMainScreen = () => (
    <div className="cabinet">
      <div className="cabinet-layout">
        <aside className="sidebar">
          <div className="sidebar-cards">
            {userCards.map(card => {
              const bgUrl = cardBgs[card.id];
              const cardStyle = {
                backgroundImage: bgUrl ? `url(${bgUrl})` : card.color,
              };

              return (
                <div 
                  key={card.id} 
                  className={`sidebar-card ${card.isBlocked ? 'blocked' : ''}`} 
                  onClick={() => !card.isBlocked && handleCardClick(card)}
                  style={cardStyle}
                >
                  <div className="sidebar-card-overlay"></div>
                  <div className="sidebar-card-icon">
                    {React.createElement(card.iconComponent)}
                  </div>
                  <div className="sidebar-card-info">
                    <div className="sidebar-card-balance">{card.balance.toLocaleString('ru-RU', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</div>
                    <div className="sidebar-card-type">{card.type}</div>
                    <div className="sidebar-card-number">{card.number}</div>
                    {card.isBlocked && <div className="card-blocked-label">Заблокирована</div>}
                  </div>
                </div>
              );
            })}
          </div>

          {activeProducts.length > 0 && (
            <div className="sidebar-products">
              {activeProducts.map(product => (
                <div key={product.id} className="sidebar-product">
                  <div className="sidebar-product-name">{product.name}</div>
                  <div className="sidebar-product-balance">{product.balance}</div>
                </div>
              ))}
            </div>
          )}

          <button className="sidebar-new-btn" onClick={() => setShowModal(true)}>
            <span className="cabinet-new-product-plus">+</span>
            <div>Новый счёт или продукт</div>
          </button>

          <button className="sidebar-logout-btn" onClick={handleLogout}>
            <FaSignOutAlt />
            <span>Выйти</span>
          </button>
        </aside>

        <main className="cabinet-main">
          <div className="cabinet-greeting">{getGreeting(USER_NAME)}</div>

          <div className="cabinet-quick-actions">
            {quickActions.map((action, idx) => {
              const IconComponent = action.iconComponent;
              return (
                <div 
                  className="cabinet-quick-action" 
                  key={idx}
                  onClick={() => handleQuickAction(action.label)}
                >
                  <div className="cabinet-quick-icon"><IconComponent /></div>
                  <div className="cabinet-quick-label">{action.label}</div>
                </div>
              );
            })}
          </div>

          <div className="cabinet-operations-block">
            <div className="cabinet-operations-header">
              <span className={tab === "traty" ? "active" : ""} onClick={() => setTab("traty")}>Траты</span>
              <span className={tab === "popoln" ? "active" : ""} onClick={() => setTab("popoln")}>Пополнения</span>
            </div>
            <div className="cabinet-operations-content">
              <div className="cabinet-operations-list">
                {currentData.map((op, idx) => (
                  <div key={idx} className="cabinet-operation-chip">
                    <span className="chip-color-indicator" style={{ backgroundColor: op.color }}></span>
                    {op.label} {op.value.toLocaleString()} ₽
                  </div>
                ))}
              </div>
              <div className="cabinet-operations-pie">
                <svg width="200" height="200" viewBox="0 0 36 36">
                  {(() => {
                    let cumulativePercent = 0;
                    return currentData.map((op, idx) => {
                      const percent = total > 0 ? (op.value / total) * 100 : 0;
                      const offset = cumulativePercent;
                      cumulativePercent += percent;
                      return (
                        <circle
                          key={idx}
                          r="16"
                          cx="18"
                          cy="18"
                          fill="none"
                          stroke={op.color}
                          strokeWidth="4"
                          strokeDasharray={`${percent} ${100 - percent}`}
                          strokeDashoffset={-offset}
                          transform="rotate(-90 18 18)"
                        />
                      );
                    });
                  })()}
                </svg>
                <div className="cabinet-operations-pie-label">
                  {total.toLocaleString()} ₽<br />{pieLabel}
                </div>
              </div>
            </div>
          </div>

          <div className="cabinet-recent-transactions">
            <div className="cabinet-transactions-header">
              <h3>История операций</h3>
              <button className="cabinet-view-all-btn" onClick={() => setShowHistory(true)}>
                Посмотреть все
              </button>
            </div>
            <div className="transactions-list">
              {recentTransactions.slice(0, 3).map(transaction => (
                <div key={transaction.id} className="transaction-item">
                  <div className="transaction-info">
                    <div className="transaction-title">{transaction.title}</div>
                    <div className="transaction-date">{transaction.date}</div>
                  </div>
                  <div className={`transaction-amount ${transaction.type}`}>
                    {transaction.type === 'income' ? '+' : '-'}{transaction.amount.toLocaleString()} ₽
                  </div>
                </div>
              ))}
            </div>
          </div>
        </main>
      </div>

      {showModal && (
        <ModalNewProduct
          show={showModal}
          onClose={() => setShowModal(false)}
          onProductActivate={handleProductActivation}
        />
      )}

      {showCard && (
        <ModalCardDetails
          show={showCard}
          onClose={() => setShowCard(false)}
          cardDetails={selectedCard}
          onBlock={handleBlockCardRequest}
          onRequisites={handleRequisitesRequest}
          onTopUp={handleTopUpRequest}
          cardBgUrl={selectedCard ? cardBgs[selectedCard.id] : null}
          onBgChange={handleCardBgChange}
        />
      )}

      {showHistory && (
        <ModalTransactionHistory
          show={showHistory}
          onClose={() => setShowHistory(false)}
          transactions={recentTransactions}
        />
      )}

      {showTransfer && (
        <ModalTransfer
          show={showTransfer}
          onClose={() => setShowTransfer(false)}
          userCards={[...userCards, ...activeProducts]}
          onConfirmTransfer={handleMakeTransfer}
        />
      )}

      {showMap && (
        <ModalMap
          show={showMap}
          onClose={() => setShowMap(false)}
        />
      )}

      {showExchangeRates && (
        <ModalExchangeRates
          show={showExchangeRates}
          onClose={() => setShowExchangeRates(false)}
        />
      )}

      {showRequisites && (
        <ModalCardRequisites
          show={showRequisites}
          onClose={() => setShowRequisites(false)}
          cardDetails={selectedCard}
        />
      )}

      {showTopUp && (
        <ModalTopUp
          show={showTopUp}
          onClose={() => setShowTopUp(false)}
          onConfirm={handleConfirmTopUp}
          cardName={selectedCard?.name}
        />
      )}

      {showConfirmBlock && (
        <ModalConfirmBlock
          show={showConfirmBlock}
          onClose={() => setShowConfirmBlock(false)}
          onConfirm={handleConfirmBlock}
          cardName={selectedCard?.name}
        />
      )}

      {showCryptoWallet && (
        <ModalCryptoWallet
          show={showCryptoWallet}
          onClose={() => setShowCryptoWallet(false)}
        />
      )}
    </div>
  );

  if (activeScreen === "profile") {
    return <CabinetProfile />;
  }
  if (activeScreen === "forum") {
    return <CabinetForum />;
  }

  return renderMainScreen();
};

export default Cabinet; 