import React, { useState, useEffect, useRef } from 'react';
import { FaTimes, FaMapMarkerAlt, FaMoneyBillWave } from 'react-icons/fa';
import { terminals } from '../constants/terminals';
import './ModalMap.css';

const DEFAULT_LOCATION = { lat: 43.1168, lng: 131.8875 };

const ModalMap = ({ show, onClose }) => {
  const [userLocation, setUserLocation] = useState(DEFAULT_LOCATION);
  const [selectedTerminal, setSelectedTerminal] = useState(null);
  const [sortedTerminals, setSortedTerminals] = useState(terminals);
  const mapRef = useRef(null);
  const mapInstanceRef = useRef(null);

  useEffect(() => {
    if (show && window.ymaps && !mapInstanceRef.current) {
      window.ymaps.ready(() => {
        if (!mapInstanceRef.current) {
          const map = new window.ymaps.Map(mapRef.current, {
            center: [userLocation.lat, userLocation.lng],
            zoom: 12,
            controls: ['zoomControl', 'fullscreenControl']
          }, {
            suppressMapOpenBlock: true
          });

          // Настраиваем внешний вид карты
          map.panes.get('ground').getElement().style.filter = 'grayscale(15%) brightness(95%)';

          // Добавляем возможность перетаскивания карты
          map.behaviors.enable('drag');

          // Добавляем маркеры на карту
          terminals.forEach(terminal => {
            const placemark = new window.ymaps.Placemark(
              [terminal.coordinates.lat, terminal.coordinates.lng],
              {
                balloonContentBody: `
                  <div class="ymaps-balloon">
                    <h3>${terminal.name}</h3>
                    <p>${terminal.address}</p>
                  </div>
                `
              },
              {
                preset: terminal.isATM ? 'islands#blueMoneyCircleIcon' : 'islands#violetBankCircleIcon',
                iconColor: terminal.isATM ? '#6c74c9' : '#524CA1'
              }
            );
            map.geoObjects.add(placemark);

            placemark.events.add('click', () => {
              setSelectedTerminal(terminal);
            });
          });

          mapInstanceRef.current = map;
        }
      });
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.destroy();
        mapInstanceRef.current = null;
      }
    };
  }, [show, userLocation]);

  useEffect(() => {
    if (show) {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            const location = {
              lat: position.coords.latitude,
              lng: position.coords.longitude
            };
            setUserLocation(location);
            
            const sorted = [...terminals].sort((a, b) => {
              const distA = calculateDistance(
                location.lat,
                location.lng,
                a.coordinates.lat,
                a.coordinates.lng
              );
              const distB = calculateDistance(
                location.lat,
                location.lng,
                b.coordinates.lat,
                b.coordinates.lng
              );
              return distA - distB;
            });
            setSortedTerminals(sorted);
          },
          (error) => {
            console.error('Error getting location:', error);
            setUserLocation(DEFAULT_LOCATION);
            setSortedTerminals(terminals);
          }
        );
      }
    }
  }, [show]);

  const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
      Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  };

  const handleTerminalClick = (terminal) => {
    setSelectedTerminal(terminal);
    if (mapInstanceRef.current) {
      mapInstanceRef.current.setCenter([terminal.coordinates.lat, terminal.coordinates.lng], 15, {
        duration: 500
      });
    }
  };

  if (!show) return null;

  return (
    <div className="modal-overlay">
      <div className="map-modal">
        <button className="modal-close" onClick={onClose}>
          <FaTimes />
        </button>
        <h2>Отделения и банкоматы</h2>
        <div className="map-container">
          <div className="map" ref={mapRef}></div>
          <div className="terminals-list">
            <h3>Ближайшие отделения</h3>
            <div className="terminals">
              {sortedTerminals.map((terminal) => {
                const distance = calculateDistance(
                  userLocation.lat,
                  userLocation.lng,
                  terminal.coordinates.lat,
                  terminal.coordinates.lng
                ).toFixed(1);

                return (
                  <div
                    key={terminal.name}
                    className={`terminal-item ${selectedTerminal?.name === terminal.name ? 'selected' : ''}`}
                    onClick={() => handleTerminalClick(terminal)}
                  >
                    <div className="terminal-icon">
                      {terminal.isATM ? <FaMoneyBillWave /> : <FaMapMarkerAlt />}
                    </div>
                    <div className="terminal-info">
                      <h4>{terminal.name}</h4>
                      <p>{terminal.address}</p>
                      <span className="distance">{distance} км</span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ModalMap; 