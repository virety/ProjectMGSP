import React from "react";
import "./Services.css";
import { FaMoneyBillWave, FaMapMarkerAlt, FaCalculator } from "react-icons/fa";

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

const Services = ({ onShowExchangeRates, onShowDepositCalculator, onShowMap }) => {
  const handleServiceClick = (service) => {
    switch (service.title) {
      case "Курсы валют":
        onShowExchangeRates();
        break;
      case "Отделения и банкоматы":
        onShowMap();
        break;
      case "Рассчитать вклад":
        onShowDepositCalculator();
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
    </section>
  );
};

export default Services; 