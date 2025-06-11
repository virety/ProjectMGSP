import React, { useState } from "react";
import "./Services.css";
import { FaMoneyBillWave, FaMapMarkerAlt, FaCalculator } from "react-icons/fa";
import ModalExchangeRates from "./ModalExchangeRates";
import ModalDepositCalculator from "./ModalDepositCalculator";
import ModalMap from "./ModalMap";

const services = [
  {
    icon: <FaMoneyBillWave size={40} />, 
    title: "Курсы валют",
    desc: "Актуальные курсы валют и конвертер",
    button: "Показать курсы",
    disabled: false
  },
  {
    icon: <FaMapMarkerAlt size={40} />, 
    title: "Отделения и банкоматы",
    desc: "Найдите ближайшее отделение или банкомат",
    button: "Найти на карте",
    disabled: false
  },
  {
    icon: <FaCalculator size={40} />, 
    title: "Рассчитать вклад",
    desc: "Рассчитайте доход по вкладу",
    button: "Рассчитать",
    disabled: false
  }
];

const Services = () => {
  const [showExchangeRates, setShowExchangeRates] = useState(false);
  const [showDepositCalculator, setShowDepositCalculator] = useState(false);
  const [showMap, setShowMap] = useState(false);

  const handleServiceClick = (service) => {
    switch (service.title) {
      case "Курсы валют":
        setShowExchangeRates(true);
        break;
      case "Отделения и банкоматы":
        setShowMap(true);
        break;
      case "Рассчитать вклад":
        setShowDepositCalculator(true);
        break;
      default:
        break;
    }
  };

  return (
    <section className="nyota-services" id="services">
      <h2>Сервисы</h2>
      <div className="nyota-services__cards">
        {services.map((s, i) => (
          <div className="nyota-service-card" key={i}>
            <div className="nyota-service-card__icon">{s.icon}</div>
            <div className="nyota-service-card__title">{s.title}</div>
            <div className="nyota-service-card__desc">{s.desc}</div>
            <button 
              className="nyota-service-card__btn" 
              disabled={s.disabled}
              onClick={() => handleServiceClick(s)}
            >
              {s.button}
            </button>
          </div>
        ))}
      </div>

      <ModalExchangeRates 
        show={showExchangeRates}
        onClose={() => setShowExchangeRates(false)}
      />
      <ModalDepositCalculator
        show={showDepositCalculator}
        onClose={() => setShowDepositCalculator(false)}
      />
      <ModalMap
        show={showMap}
        onClose={() => setShowMap(false)}
      />
    </section>
  );
};

export default Services; 