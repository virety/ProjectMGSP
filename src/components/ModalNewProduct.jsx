import React, { useState } from "react";
import "./ModalNewProduct.css";
import ModalDepositCalc from "./ModalDepositCalc";
import ModalCreditChoice from "./ModalCreditChoice";
import ModalMortgageCalc from "./ModalMortgageCalc";
import ModalSavingsGoal from "./ModalSavingsGoal";

const products = [
  {
    icon: "💰",
    title: "Вклад",
    description: "Откройте вклад с выгодной процентной ставкой"
  },
  {
    icon: "💳",
    title: "Кредит",
    description: "Выберите подходящий кредит для ваших целей"
  },
  {
    icon: "🏠",
    title: "Ипотека",
    description: "Реализуйте мечту о собственном жилье"
  },
  {
    icon: "🎯",
    title: "Накопительный счёт",
    description: "Копите на важные цели с накопительным счётом"
  }
];

const ModalNewProduct = ({ show, onClose, onProductActivate }) => {
  const [showDepositCalc, setShowDepositCalc] = useState(false);
  const [showCreditChoice, setShowCreditChoice] = useState(false);
  const [showMortgageCalc, setShowMortgageCalc] = useState(false);
  const [showSavingsGoal, setShowSavingsGoal] = useState(false);

  if (!show) return null;

  const handleProductClick = (product) => {
    switch (product.title) {
      case "Вклад":
        setShowDepositCalc(true);
        break;
      case "Кредит":
        setShowCreditChoice(true);
        break;
      case "Ипотека":
        setShowMortgageCalc(true);
        break;
      case "Накопительный счёт":
        setShowSavingsGoal(true);
        break;
      default:
        break;
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <div className="modal-title">Выберите продукт</div>
        <div className="modal-items">
          {products.map((product, index) => (
            <div
              key={index}
              className="modal-item"
              onClick={() => handleProductClick(product)}
            >
              <div className="modal-item-icon">{product.icon}</div>
              <div className="modal-item-content">
                <div className="modal-item-title">{product.title}</div>
                <div className="modal-item-description">{product.description}</div>
              </div>
            </div>
          ))}
        </div>
        <button className="modal-close" onClick={onClose}>×</button>
      </div>

      <ModalDepositCalc 
        show={showDepositCalc} 
        onClose={() => setShowDepositCalc(false)} 
        onSuccess={() => {
          onProductActivate({
            id: Date.now(),
            name: 'Вклад',
            balance: '500 000 ₽'
          });
          setShowDepositCalc(false);
        }}
      />
      <ModalCreditChoice 
        show={showCreditChoice} 
        onClose={() => setShowCreditChoice(false)} 
        onSuccess={() => {
          onProductActivate({
            id: Date.now(),
            name: 'Потребительский кредит',
            balance: '300 000 ₽'
          });
          setShowCreditChoice(false);
        }}
      />
      <ModalMortgageCalc 
        show={showMortgageCalc} 
        onClose={() => setShowMortgageCalc(false)} 
        onSuccess={() => {
          onProductActivate({
            id: Date.now(),
            name: 'Ипотека',
            balance: '2 500 000 ₽'
          });
          setShowMortgageCalc(false);
        }}
      />
      <ModalSavingsGoal 
        show={showSavingsGoal} 
        onClose={() => setShowSavingsGoal(false)} 
        onSuccess={() => {
          onProductActivate({
            id: Date.now(),
            name: 'Накопительный счет',
            balance: '100 000 ₽'
          });
          setShowSavingsGoal(false);
        }}
      />
    </div>
  );
};

export default ModalNewProduct; 