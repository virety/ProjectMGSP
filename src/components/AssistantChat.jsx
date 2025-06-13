import React, { useState, useEffect, useRef } from 'react';
import './AssistantChat.css';
import { FaRegPaperPlane, FaTimes, FaExpandAlt, FaCompressAlt, FaRobot, FaBroom } from 'react-icons/fa';
import assistantAvatar from '../assets/nyotik_icon.png';

const INITIAL_MESSAGE = {
  id: 1,
  text: "Здравствуйте! Я ваш персональный ассистент. Как я могу помочь вам сегодня?",
  isBot: true
};

const AssistantChat = () => {
  const [isOpen, setIsOpen] = useState(() => {
    return localStorage.getItem('chatIsOpen') === 'true';
  });
  
  const [isModalOpen, setIsModalOpen] = useState(() => {
    return localStorage.getItem('chatIsModal') === 'true';
  });

  const [messages, setMessages] = useState(() => {
    const savedMessages = localStorage.getItem('chatMessages');
    if (savedMessages) {
      return JSON.parse(savedMessages);
    }
    return [INITIAL_MESSAGE];
  });

  const [inputMessage, setInputMessage] = useState('');

  // Сохраняем состояние чата
  useEffect(() => {
    localStorage.setItem('chatMessages', JSON.stringify(messages));
  }, [messages]);

  useEffect(() => {
    localStorage.setItem('chatIsOpen', isOpen);
    localStorage.setItem('chatIsModal', isModalOpen);
  }, [isOpen, isModalOpen]);

  const toggleChat = () => {
    setIsOpen(!isOpen);
  };

  const toggleModal = () => {
    setIsModalOpen(!isModalOpen);
    setIsOpen(false);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (inputMessage.trim()) {
      const newUserMessage = {
        id: messages.length + 1,
        text: inputMessage,
        isBot: false,
        timestamp: new Date().toISOString()
      };

      setMessages(prevMessages => [...prevMessages, newUserMessage]);
      setInputMessage('');

      // Имитация ответа бота
      setTimeout(() => {
        const botResponse = {
          id: messages.length + 2,
          text: "Спасибо за ваше сообщение! Я обрабатываю ваш запрос.",
          isBot: true,
          timestamp: new Date().toISOString()
        };
        setMessages(prevMessages => [...prevMessages, botResponse]);
      }, 1000);
    }
  };

  const clearChat = () => {
    if (window.confirm('Вы уверены, что хотите очистить историю чата?')) {
      setMessages([INITIAL_MESSAGE]);
    }
  };

  const renderMessages = () => {
    return messages.map(message => (
      <div key={message.id} className={`message ${message.isBot ? 'bot' : 'user'}`}>
        {message.isBot && (
          <div className="bot-avatar">
            <img src={assistantAvatar} alt="Nyotik" />
          </div>
        )}
        <div className="message-content">
          <p>{message.text}</p>
          {message.timestamp && (
            <small className="message-timestamp">
              {new Date(message.timestamp).toLocaleTimeString()}
            </small>
          )}
        </div>
      </div>
    ));
  };

  const chatContent = (
    <div className={`chat-content ${isModalOpen ? 'modal' : ''}`}>
      <div className="chat-header">
        <h3>Ассистент</h3>
        <div className="chat-controls">
          <button 
            className="clear-btn" 
            onClick={clearChat}
            title="Очистить чат"
          >
            <FaBroom />
          </button>
          {!isModalOpen && (
            <button className="expand-btn" onClick={toggleModal}>
              <FaExpandAlt />
            </button>
          )}
          {isModalOpen && (
            <button className="minimize-btn" onClick={toggleModal}>
              <FaCompressAlt />
            </button>
          )}
          <button 
            className="close-btn" 
            onClick={() => {
              setIsOpen(false);
              setIsModalOpen(false);
            }}
          >
            <FaTimes />
          </button>
        </div>
      </div>
      <div className="messages-container">
        {renderMessages()}
      </div>
      <form onSubmit={handleSubmit} className="chat-input">
        <input
          type="text"
          value={inputMessage}
          onChange={(e) => setInputMessage(e.target.value)}
          placeholder="Введите сообщение..."
        />
        <button type="submit">
          <FaRegPaperPlane />
        </button>
      </form>
    </div>
  );

  return (
    <div className="assistant-chat-container">
      {!isOpen && (
        <button className="chat-toggle" onClick={toggleChat} title="Открыть чат">
          <img src={assistantAvatar} alt="Открыть чат" className="chat-toggle-icon" />
        </button>
      )}
      {(isOpen || isModalOpen) && (
        <div className={`chat-widget ${isModalOpen ? 'modal-view' : ''}`}>
          {chatContent}
        </div>
      )}
    </div>
  );
};

export default AssistantChat; 