import React from "react";
import "./Cabinet.css";

const Cabinet = ({ onLogout }) => (
  <div className="cabinet-page">
    <h2>Личный кабинет</h2>
    <div className="cabinet-balance-card">
      <div className="cabinet-balance-label">Общий баланс</div>
      <div className="cabinet-balance-amount">124 500 ₽</div>
    </div>
    <div className="cabinet-cards-list">
      <div className="cabinet-card">
        <div className="cabinet-card-title">Дебетовая карта</div>
        <div className="cabinet-card-balance">48 200 ₽</div>
      </div>
      <div className="cabinet-card">
        <div className="cabinet-card-title">Вклад "Космос"</div>
        <div className="cabinet-card-balance">76 300 ₽</div>
      </div>
    </div>
    <button className="modal-auth-btn" onClick={onLogout}>Выйти</button>
  </div>
);

export default Cabinet; 