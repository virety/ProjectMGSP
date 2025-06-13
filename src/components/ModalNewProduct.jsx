import React, { useState } from "react";
import "./ModalNewProduct.css";
import ModalDepositCalc from "./ModalDepositCalc";
import ModalCreditChoice from "./ModalCreditChoice";
import ModalMortgageCalc from "./ModalMortgageCalc";
import ModalCardIssue from "./ModalCardIssue";
import { FaPiggyBank, FaCreditCard, FaHome, FaTimes, FaAddressCard } from "react-icons/fa";

const products = [
  {
    icon: <FaPiggyBank />,
    title: "Вклад",
    description: "Откройте вклад с выгодной процентной ставкой"
  },
  {
    icon: <FaCreditCard />,
    title: "Кредит",
    description: "Выберите подходящий кредит для ваших целей"
  },
  {
    icon: <FaHome />,
    title: "Ипотека",
    description: "Реализуйте мечту о собственном жилье"
  },
  {
    icon: <FaAddressCard />,
    title: "Карта",
    description: "Закажите новую дебетовую или кредитную карту"
  }
];

const ModalNewProduct = ({ show, onClose, onProductActivate }) => {
  const [showDepositCalc, setShowDepositCalc] = useState(false);
  const [showCreditChoice, setShowCreditChoice] = useState(false);
  const [showMortgageCalc, setShowMortgageCalc] = useState(false);
  const [showCardIssue, setShowCardIssue] = useState(false);
  const [showProductChoice, setShowProductChoice] = useState(true);

  if (!show) return null;

  const handleProductClick = (product) => {
    setShowProductChoice(false);
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
      case "Карта":
        setShowCardIssue(true);
        break;
      default:
        break;
    }
  };

  const handleModalClose = (modalType) => {
    switch (modalType) {
      case 'deposit':
        setShowDepositCalc(false);
        break;
      case 'credit':
        setShowCreditChoice(false);
        break;
      case 'mortgage':
        setShowMortgageCalc(false);
        break;
      case 'card':
        setShowCardIssue(false);
        break;
      default:
        break;
    }
    setShowProductChoice(true);
  };

  // Показываем только одно активное окно
  if (showDepositCalc) {
    return (
      <ModalDepositCalc 
        show={true} 
        onClose={() => handleModalClose('deposit')}
        onSuccess={() => {
          onProductActivate({
            id: Date.now(),
            name: 'Вклад',
            balance: '500 000 ₽'
          });
          setShowDepositCalc(false);
          onClose();
        }}
      />
    );
  }

  if (showCreditChoice) {
    return (
      <ModalCreditChoice 
        show={true} 
        onClose={() => handleModalClose('credit')}
        onSuccess={() => {
          onProductActivate({
            id: Date.now(),
            name: 'Потребительский кредит',
            balance: '300 000 ₽'
          });
          setShowCreditChoice(false);
          onClose();
        }}
      />
    );
  }

  if (showMortgageCalc) {
    return (
      <ModalMortgageCalc 
        show={true} 
        onClose={() => handleModalClose('mortgage')}
        onSuccess={() => {
          onProductActivate({
            id: Date.now(),
            name: 'Ипотека',
            balance: '3 000 000 ₽'
          });
          setShowMortgageCalc(false);
          onClose();
        }}
      />
    );
  }

  if (showCardIssue) {
    return (
      <ModalCardIssue 
        show={true} 
        onClose={() => handleModalClose('card')}
        onSuccess={() => {
          onProductActivate({
            id: Date.now(),
            name: 'Новая карта',
            balance: '0 ₽'
          });
          setShowCardIssue(false);
          onClose();
        }}
      />
    );
  }

  // Показываем окно выбора продукта
  if (showProductChoice) {
    return (
      <div className="modal-new-product-overlay" onClick={onClose}>
        <div className="modal-new-product" onClick={e => e.stopPropagation()}>
          <div className="modal-new-product-title">Выберите продукт</div>
          <div className="modal-new-product-items">
            {products.map((product, index) => (
              <div
                key={index}
                className="modal-new-product-item"
                onClick={() => handleProductClick(product)}
              >
                <div className="modal-new-product-item-icon">{product.icon}</div>
                <div className="modal-new-product-item-content">
                  <div className="modal-new-product-item-title">{product.title}</div>
                  <div className="modal-new-product-item-description">{product.description}</div>
                </div>
              </div>
            ))}
          </div>
          <button className="modal-new-product-close" onClick={onClose}><FaTimes /></button>
        </div>
      </div>
    );
  }

  return null;
};

export default ModalNewProduct; 