import React, { useState } from "react";
import "./Cabinet.css";
import ModalNewProduct from "./ModalNewProduct";
import ModalCardDetails from "./ModalCardDetails";

const USER_NAME = "Анна";

const mainCard = {
  type: "Основная карта",
  number: "**** 1234",
  balance: "353,45 ₽",
  currency: "RUB",
  icon: "💳",
  status: "2 D",
  color: "linear-gradient(135deg, #6c74c9 0%, #18114D 100%)",
  expiryDate: "12/25"
};

const actions = [
  { label: "Открыть накопительный счет" }
];

const quickActions = [
  { icon: "📱", label: "Перевести по номеру телефона" },
  { icon: "📄", label: "Перевести по реквизитам" },
  { icon: "💳", label: "Оплатить мобильный" },
  { icon: "🔍", label: "Распознать квитанцию" }
];

const operations = [
  { label: "Переводы", value: 16167, color: "#6c74c9" },
  { label: "Супермаркеты", value: 5054, color: "#8b5cf6" },
  { label: "Рестораны", value: 3895, color: "#a5b4fc" },
  { label: "Такси", value: 502, color: "#524CA1" },
  { label: "Маркетплейсы", value: 212, color: "#b2b2d6" },
  { label: "Остальное", value: 287, color: "#d4bdea" }
];

const recentTransactions = [
  { id: 1, title: "Перевод от Ивана", amount: "+15,000 ₽", date: "Сегодня, 14:30", type: "income" },
  { id: 2, title: "Пятёрочка", amount: "-2,450 ₽", date: "Сегодня, 12:15", type: "expense" },
  { id: 3, title: "Такси", amount: "-350 ₽", date: "Вчера, 18:45", type: "expense" }
];

const savingsGoals = [
  { title: "Новый телефон", current: 25000, target: 50000, color: "#6c74c9" },
  { title: "Отпуск", current: 15000, target: 100000, color: "#8b5cf6" }
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

const Cabinet = () => {
  const [tab, setTab] = useState("traty");
  const [showModal, setShowModal] = useState(false);
  const [showCard, setShowCard] = useState(false);
  const total = operations.reduce((sum, op) => sum + op.value, 0);

  return (
    <div className="cabinet-layout">
      <aside className="sidebar">
        <div className="sidebar-cards">
          <div className="sidebar-card" onClick={() => setShowCard(true)} style={{ cursor: 'pointer' }}>
            <div className="sidebar-card-icon">{mainCard.icon}</div>
            <div className="sidebar-card-info">
              <div className="sidebar-card-balance">{mainCard.balance}</div>
              <div className="sidebar-card-type">{mainCard.type}</div>
              <div className="sidebar-card-number">{mainCard.number}</div>
            </div>
            <div className="sidebar-card-status">{mainCard.status}</div>
          </div>
        </div>
        <div className="sidebar-actions">
          {actions.map((action, idx) => (
            <div className="sidebar-action-block" key={idx}>
              <div className="sidebar-action">
                <div className="sidebar-action-circle">+</div>
                <div className="sidebar-action-label">{action.label}</div>
              </div>
            </div>
          ))}
        </div>
        <button className="sidebar-new-btn" onClick={() => setShowModal(true)}>
          Новый счет или продукт
        </button>
        <ModalNewProduct show={showModal} onClose={() => setShowModal(false)} />
        <ModalCardDetails show={showCard} onClose={() => setShowCard(false)} card={mainCard} />
      </aside>
      <main className="cabinet-main">
        <div className="cabinet-greeting">{getGreeting(USER_NAME)}</div>
        <div className="cabinet-quick-actions">
          {quickActions.map((a, idx) => (
            <div className="cabinet-quick-action" key={idx}>
              <div className="cabinet-quick-icon">{a.icon}</div>
              <div className="cabinet-quick-label">{a.label}</div>
            </div>
          ))}
        </div>

        <div className="cabinet-grid">
          <div className="cabinet-operations-block">
            <div className="cabinet-operations-header">
              <span className={tab === "traty" ? "active" : ""} onClick={() => setTab("traty")}>Траты</span>
              <span className={tab === "popoln" ? "active" : ""} onClick={() => setTab("popoln")}>Пополнения</span>
              <span className="cabinet-operations-link">Операции в июне &gt;</span>
            </div>
            <div className="cabinet-operations-content">
              <div className="cabinet-operations-list">
                {operations.map((op, idx) => (
                  <span key={idx} style={{ background: op.color }} className="cabinet-operation-chip">
                    {op.label} {op.value.toLocaleString()} ₽
                  </span>
                ))}
              </div>
              <div className="cabinet-operations-pie">
                <svg width="200" height="200" viewBox="0 0 36 36">
                  {(() => {
                    let acc = 0;
                    return operations.map((op, idx) => {
                      const val = (op.value / total) * 100;
                      const dash = (val * 100) / 100;
                      const el = (
                        <circle
                          key={idx}
                          r="16"
                          cx="18"
                          cy="18"
                          fill="none"
                          stroke={op.color}
                          strokeWidth="4"
                          strokeDasharray={`${dash} ${100 - dash}`}
                          strokeDashoffset={-acc}
                        />
                      );
                      acc -= dash;
                      return el;
                    });
                  })()}
                </svg>
                <div className="cabinet-operations-pie-label">{total.toLocaleString()} ₽<br />Траты</div>
              </div>
            </div>
          </div>

          <div className="cabinet-recent-transactions">
            <h3>Последние операции</h3>
            <div className="transactions-list">
              {recentTransactions.map(transaction => (
                <div key={transaction.id} className="transaction-item">
                  <div className="transaction-info">
                    <div className="transaction-title">{transaction.title}</div>
                    <div className="transaction-date">{transaction.date}</div>
                  </div>
                  <div className={`transaction-amount ${transaction.type}`}>
                    {transaction.amount}
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="cabinet-savings-goals">
            <h3>Цели накоплений</h3>
            <div className="savings-list">
              {savingsGoals.map((goal, idx) => (
                <div key={idx} className="savings-goal">
                  <div className="savings-goal-info">
                    <div className="savings-goal-title">{goal.title}</div>
                    <div className="savings-goal-progress">
                      <div 
                        className="savings-goal-bar" 
                        style={{ 
                          width: `${(goal.current / goal.target) * 100}%`,
                          background: goal.color
                        }}
                      />
                    </div>
                    <div className="savings-goal-amount">
                      {goal.current.toLocaleString()} ₽ из {goal.target.toLocaleString()} ₽
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Cabinet; 