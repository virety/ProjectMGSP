import React, { useState } from "react";
import "./ModalSavingsGoal.css";

const ModalSavingsGoal = ({ show, onClose }) => {
  const [goal, setGoal] = useState("");
  const [amount, setAmount] = useState("");
  const [showSuccess, setShowSuccess] = useState(false);

  if (!show) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    setShowSuccess(true);
  };

  return (
    <div className="modal-savingsgoal-overlay" onClick={onClose}>
      <div className="modal-savingsgoal" onClick={e => e.stopPropagation()}>
        <button className="modal-savingsgoal-close" onClick={onClose}>×</button>
        
        {!showSuccess ? (
          <>
            <div className="modal-savingsgoal-title">Накопительный счет</div>
            <form className="modal-savingsgoal-form" onSubmit={handleSubmit}>
              <div className="modal-savingsgoal-field">
                <label>Цель накопления</label>
                <div className="modal-savingsgoal-input-group">
                  <input
                    type="text"
                    value={goal}
                    onChange={(e) => setGoal(e.target.value)}
                    placeholder="Например: Новый автомобиль"
                    className="modal-savingsgoal-input"
                    required
                  />
                </div>
              </div>

              <div className="modal-savingsgoal-field">
                <label>Сумма накопления</label>
                <div className="modal-savingsgoal-input-group">
                  <input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="Введите сумму"
                    className="modal-savingsgoal-input"
                    required
                    min="1000"
                  />
                  <span className="modal-savingsgoal-currency">₽</span>
                </div>
              </div>

              <button 
                type="submit"
                className="modal-savingsgoal-submit"
                disabled={!goal || !amount}
              >
                Открыть счет
              </button>
            </form>
          </>
        ) : (
          <div className="modal-savingsgoal-success">
            <h2>Счет успешно открыт!</h2>
            <p>Начните накопление прямо сейчас</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ModalSavingsGoal; 