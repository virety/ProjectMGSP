import React from 'react';
import { FaTimes } from 'react-icons/fa';
import './ModalATMs.css';

const atms = [
  {
    id: 1,
    type: 'Банкомат',
    address: 'ул. Ленина, 45',
    workHours: '24/7',
    services: ['Снятие наличных', 'Внесение наличных', 'Оплата услуг']
  },
  {
    id: 2,
    type: 'Терминал',
    address: 'пр. Мира, 78',
    workHours: '09:00 - 22:00',
    services: ['Оплата услуг', 'Пополнение счета']
  },
  {
    id: 3,
    type: 'Банкомат',
    address: 'ул. Гагарина, 12',
    workHours: '24/7',
    services: ['Снятие наличных', 'Внесение наличных']
  },
  {
    id: 4,
    type: 'Банкомат',
    address: 'ул. Пушкина, 89',
    workHours: '24/7',
    services: ['Снятие наличных', 'Внесение наличных', 'Оплата услуг']
  },
  {
    id: 5,
    type: 'Терминал',
    address: 'ул. Советская, 154',
    workHours: '08:00 - 20:00',
    services: ['Оплата услуг', 'Пополнение счета']
  }
];

const ModalATMs = ({ show, onClose }) => {
  if (!show) return null;

  return (
    <div className="modal-atms-overlay" onClick={onClose}>
      <div className="modal-atms" onClick={e => e.stopPropagation()}>
        <button className="modal-atms-close" onClick={onClose}>
          <FaTimes />
        </button>

        <h2 className="modal-atms-title">Банкоматы и терминалы</h2>

        <div className="modal-atms-list">
          {atms.map(atm => (
            <div key={atm.id} className="modal-atms-item">
              <div className="modal-atms-item-header">
                <div className="modal-atms-item-type">{atm.type}</div>
                <div className="modal-atms-item-hours">{atm.workHours}</div>
              </div>
              
              <div className="modal-atms-item-address">
                {atm.address}
              </div>

              <div className="modal-atms-item-services">
                {atm.services.map((service, index) => (
                  <span key={index} className="modal-atms-item-service">
                    {service}
                  </span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default ModalATMs; 