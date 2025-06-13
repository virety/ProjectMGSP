import React, { useState } from 'react';
import { FaTimes, FaUpload } from 'react-icons/fa';
import { RiUser3Fill } from 'react-icons/ri';
import './ModalProfileSettings.css';

const ModalProfileAvatar = ({ show, onClose, onSave }) => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);

  const handleFileSelect = (e) => {
    const file = e.target.files[0];
    if (file && file.type.startsWith('image/')) {
      setSelectedFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreviewUrl(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSave = () => {
    if (selectedFile) {
      onSave(selectedFile);
    }
    onClose();
  };

  if (!show) return null;

  return (
    <div className="modal-overlay">
      <div className="modal-profile-settings">
        <button className="modal-close" onClick={onClose}>
          <FaTimes />
        </button>
        <h2>Изменить аватар</h2>
        
        <div className="avatar-preview">
          {previewUrl ? (
            <img src={previewUrl} alt="Preview" className="avatar-image" />
          ) : (
            <div className="avatar-placeholder">
              <RiUser3Fill size={50} />
            </div>
          )}
        </div>

        <div className="avatar-upload">
          <label className="upload-button">
            <FaUpload />
            <span>Загрузить фото</span>
            <input
              type="file"
              accept="image/*"
              onChange={handleFileSelect}
              style={{ display: 'none' }}
            />
          </label>
          <p className="upload-info">
            Поддерживаемые форматы: JPG, PNG. Максимальный размер: 5MB
          </p>
        </div>

        <div className="modal-actions">
          <button className="modal-cancel" onClick={onClose}>Отмена</button>
          <button 
            className="modal-save" 
            onClick={handleSave}
            disabled={!selectedFile}
          >
            Сохранить
          </button>
        </div>
      </div>
    </div>
  );
};

export default ModalProfileAvatar; 