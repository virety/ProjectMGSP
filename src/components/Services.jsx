import React from "react";
import "./Services.css";
import { FaMoneyBillWave, FaMapMarkedAlt, FaCalculator } from "react-icons/fa";

const services = [
  {
    icon: <FaMoneyBillWave size={40} />, 
    title: "Курсы валют",
    desc: "Актуальные курсы валют",
    button: "Показать курсы",
    disabled: false
  },
  {
    icon: <FaMapMarkedAlt size={40} />, 
    title: "Отделения и банкоматы",
    desc: "Найдите ближайшее отделение или банкомат",
    button: "Найти на карте",
    disabled: true
  },
  {
    icon: <FaCalculator size={40} />, 
    title: "Рассчитать вклад",
    desc: "Калькулятор доходности по вкладам",
    button: "Рассчитать",
    disabled: true
  }
];

const Services = () => (
  <section className="nyota-services" id="services">
    <h2>Сервисы</h2>
    <div className="nyota-services__cards">
      {services.map((s, i) => (
        <div className="nyota-service-card" key={i}>
          <div className="nyota-service-card__icon">{s.icon}</div>
          <div className="nyota-service-card__title">{s.title}</div>
          <div className="nyota-service-card__desc">{s.desc}</div>
          <button className="nyota-service-card__btn" disabled={s.disabled}>{s.button}</button>
        </div>
      ))}
    </div>
  </section>
);

export default Services; 