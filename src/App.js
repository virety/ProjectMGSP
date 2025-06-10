import React, { useState } from "react";
import Header from "./components/Header";
import HeaderCabinet from "./components/HeaderCabinet";
import Services from "./components/Services";
import Products from "./components/Products";
import Hero from "./components/Hero";
import ModalAuth from "./components/ModalAuth";
import Cabinet from "./components/Cabinet";
import "./App.css";

function App() {
  const [showModal, setShowModal] = useState(false);
  const [isCabinet, setIsCabinet] = useState(false);
  const [authTab, setAuthTab] = useState("login");

  const handleLogout = () => {
    setIsCabinet(false);
    setShowModal(false);
  };

  const handleReturnToMain = () => {
    setIsCabinet(false);
  };

  if (isCabinet) return <><HeaderCabinet onLogout={handleLogout} /><Cabinet onLogout={handleLogout} onReturnToMain={handleReturnToMain} /></>;

  return (
    <div className="app-background">
      <Header isCabinet={isCabinet} onCabinetClick={() => {
        if (!isCabinet) { setAuthTab("login"); setShowModal(true); }
      }} onLogout={handleLogout} />
      <Hero
        onRegisterClick={() => { setAuthTab("register"); setShowModal(true); }}
      />
      <main>
        <Services />
        <div className="cosmic-divider"></div>
        <Products />
      </main>
      <ModalAuth show={showModal} onClose={() => setShowModal(false)} onSuccess={() => { setIsCabinet(true); setShowModal(false); }} tab={authTab} setTab={setAuthTab} />
      <footer className="nyota-footer">
        <div className="nyota-footer-line"></div>
        Nyota Bank © 2024 — Космические финансы для каждого
      </footer>
    </div>
  );
}

export default App;
