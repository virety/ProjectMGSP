import React from "react";
import "./Products.css";
import { FaCreditCard, FaPiggyBank, FaMoneyCheckAlt, FaChartLine } from "react-icons/fa";

const products = [
  {
    icon: <FaCreditCard size={36} />, 
    title: "Дебетовая карта",
    desc: "Современные карты с кэшбэком и бонусами."
  },
  {
    icon: <FaMoneyCheckAlt size={36} />, 
    title: "Кредитная карта",
    desc: "Потребительские и ипотечные кредиты на выгодных условиях."
  },
  {
    icon: <FaPiggyBank size={36} />, 
    title: "Вклады",
    desc: "Выгодные условия по вкладам и накопительным счетам."
  },
  {
    icon: <FaChartLine size={36} />, 
    title: "Инвестиции",
    desc: "Инвестиционные продукты для роста капитала."
  }
];

const Products = () => (
  <section className="nyota-products" id="products">
    <h2>Что мы предлагаем?</h2>
    <div className="nyota-products__cards">
      {products.map((p, i) => (
        <div className="nyota-product-card" key={i}>
          <div className="nyota-product-card__icon">{p.icon}</div>
          <div className="nyota-product-card__title">{p.title}</div>
          <div className="nyota-product-card__desc">{p.desc}</div>
        </div>
      ))}
    </div>
  </section>
);

export default Products; 