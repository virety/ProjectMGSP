import React from "react";
import "./ModalNewProduct.css";

const products = [
  { icon: "💳", title: "Дебетовая карта", desc: "Оформите новую карту для ежедневных расходов" },
  { icon: "🏦", title: "Вклад", desc: "Откройте вклад для накоплений и дохода" },
  { icon: "📈", title: "Инвестиционный счет", desc: "Начните инвестировать в ценные бумаги" },
  { icon: "💰", title: "Кредитка", desc: "Получите кредитную карту с бонусами" }
];

const ModalNewProduct = ({ show, onClose }) => {
  if (!show) return null;
  return (
    <div className="modal-newproduct-overlay" onClick={onClose}>
      <div className="modal-newproduct" onClick={e => e.stopPropagation()}>
        <div className="modal-newproduct-title">Выберите новый продукт</div>
        <div className="modal-newproduct-list">
          {products.map((p, idx) => (
            <div className="modal-newproduct-item" key={idx}>
              <div className="modal-newproduct-icon">{p.icon}</div>
              <div className="modal-newproduct-info">
                <div className="modal-newproduct-item-title">{p.title}</div>
                <div className="modal-newproduct-item-desc">{p.desc}</div>
              </div>
            </div>
          ))}
        </div>
        <button className="modal-newproduct-close" onClick={onClose}>Закрыть</button>
        <div className="modal-newproduct-bg"></div>
      </div>
    </div>
  );
};

export default ModalNewProduct; 