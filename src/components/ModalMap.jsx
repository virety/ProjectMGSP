import React, { useState, useEffect } from 'react';
import { FaTimes, FaMapMarkerAlt, FaMoneyBillWave } from 'react-icons/fa';
import { terminals } from '../constants/terminals';
import './ModalMap.css';

const DEFAULT_LOCATION = { lat: 43.1168, lng: 131.8875 };

const ModalMap = ({ show, onClose }) => {
  const [userLocation, setUserLocation] = useState(DEFAULT_LOCATION);
  const [selectedTerminal, setSelectedTerminal] = useState(null);
  const [sortedTerminals, setSortedTerminals] = useState(terminals);

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
  };

  if (!show) return null;

  const currentLocation = userLocation || DEFAULT_LOCATION;

  return (
    <div className="modal-overlay">
      <div className="map-modal">
        <button className="modal-close" onClick={onClose}>
          <FaTimes />
        </button>
        <h2>Отделения и банкоматы</h2>
        <div className="map-container">
          <div className="map">
            <div className="map-image">
              <img 
                src={`https://static-maps.yandex.ru/1.x/?ll=${currentLocation.lng},${currentLocation.lat}&z=12&l=map&pt=${currentLocation.lng},${currentLocation.lat},pm2rdl${terminals.map(t => `~${t.coordinates.lng},${t.coordinates.lat},pm2${t.isATM ? 'gnm' : 'blm'}`).join('')}`}
                alt="Карта"
              />
            </div>
            <div 
              className="user-location"
              style={{
                left: '50%',
                top: '50%',
                transform: 'translate(-50%, -50%)'
              }}
            >
              <div className="location-dot"></div>
            </div>
            {terminals.map((terminal) => {
              const latDiff = terminal.coordinates.lat - currentLocation.lat;
              const lngDiff = terminal.coordinates.lng - currentLocation.lng;
              const left = 50 + (lngDiff * 1000);
              const top = 50 - (latDiff * 1000);
              
              return (
                <div
                  key={terminal.name}
                  className={`terminal-marker ${terminal.isATM ? 'atm' : 'branch'} ${selectedTerminal?.name === terminal.name ? 'selected' : ''}`}
                  style={{
                    left: `${left}%`,
                    top: `${top}%`
                  }}
                  onClick={() => handleTerminalClick(terminal)}
                >
                  <div className="marker-dot"></div>
                  <div className="marker-label">{terminal.name}</div>
                </div>
              );
            })}
          </div>
          <div className="terminals-list">
            <h3>Ближайшие отделения</h3>
            <div className="terminals">
              {sortedTerminals.map((terminal) => {
                const distance = calculateDistance(
                  currentLocation.lat,
                  currentLocation.lng,
                  terminal.coordinates.lat,
                  terminal.coordinates.lng
                ).toFixed(1) + ' км';

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
                      <span className="distance">{distance}</span>
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