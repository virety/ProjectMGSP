document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('account-link')?.addEventListener('click', function(e) {
        e.preventDefault();
        openAuthModal('login');
    });

    document.getElementById('login-form')?.addEventListener('submit', function(e) {
        e.preventDefault();
        const username = document.getElementById('login-username').value;
        localStorage.setItem('currentUser', username);
        
        const userIcon = document.querySelector('#account-link .user-avatar');
        const userName = document.querySelector('#account-link .user-name');
        userIcon.innerHTML = '<i class="fas fa-user"></i>';
        userName.textContent = username.split(' ')[0];
        
        window.location.href = 'account.html';
    });

    document.getElementById('register-form')?.addEventListener('submit', function(e) {
        e.preventDefault();
        const name = document.getElementById('register-name').value;
        localStorage.setItem('currentUser', name);
        
        const userIcon = document.querySelector('#account-link .user-avatar');
        const userName = document.querySelector('#account-link .user-name');
        userIcon.innerHTML = '<i class="fas fa-user"></i>';
        userName.textContent = name.split(' ')[0];
        
        window.location.href = 'account.html';
    });

    document.querySelectorAll('nav a').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href');
            const targetElement = document.querySelector(targetId);
            
            if (targetElement) {
                window.scrollTo({
                    top: targetElement.offsetTop - 100,
                    behavior: 'smooth'
                });
            }
        });
    });

    const sections = document.querySelectorAll('section');
    const navItems = document.querySelectorAll('nav a');
    
    window.addEventListener('scroll', function() {
        let current = '';
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            
            if (pageYOffset >= (sectionTop - 150)) {
                current = section.getAttribute('id');
            }
        });
        
        navItems.forEach(item => {
            item.classList.remove('active');
            if (item.getAttribute('href') === `#${current}`) {
                item.classList.add('active');
            }
        });
    });

    const buttons = document.querySelectorAll('.btn');
    buttons.forEach(button => {
        button.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-2px)';
            this.style.boxShadow = '0 5px 15px rgba(0, 0, 0, 0.1)';
        });
        
        button.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = 'none';
        });
    });

    const cards = document.querySelectorAll('.service-card, .product-card');
    cards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.boxShadow = '0 10px 25px rgba(106, 13, 173, 0.2)';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.boxShadow = '0 5px 15px rgba(0, 0, 0, 0.05)';
        });
    });


    const authModal = document.getElementById('auth-modal');
    const passwordRecoveryModal = document.getElementById('password-recovery-modal');
    const closeModalButtons = document.querySelectorAll('.close-modal');
    const loginButtons = document.querySelectorAll('.btn.login, .login-link');
    const registerButtons = document.querySelectorAll('.btn.register, .register-link');
    const recoveryLinks = document.querySelectorAll('.recovery-link');
    const forgotPasswordLink = document.getElementById('forgot-password');
    const switchToRegisterLinks = document.querySelectorAll('.switch-to-register');
    const switchToLoginLinks = document.querySelectorAll('.switch-to-login');
    const tabButtons = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.auth-tab-content');
    
    loginButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            openAuthModal('login');
        });
    });
    
    registerButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            openAuthModal('register');
        });
    });
    
    recoveryLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            openModal(passwordRecoveryModal);
        });
    });
    
    if (forgotPasswordLink) {
        forgotPasswordLink.addEventListener('click', function(e) {
            e.preventDefault();
            closeModal(authModal);
            openModal(passwordRecoveryModal);
        });
    }
    
    switchToRegisterLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            switchTab('register');
        });
    });
    
    switchToLoginLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            switchTab('login');
        });
    });
    
    tabButtons.forEach(button => {
        button.addEventListener('click', function() {
            const tabId = this.getAttribute('data-tab');
            switchTab(tabId);
        });
    });
    
    closeModalButtons.forEach(button => {
        button.addEventListener('click', function() {
            const modal = this.closest('.modal');
            closeModal(modal);
        });
    });
    
    window.addEventListener('click', function(e) {
        if (e.target.classList.contains('modal')) {
            closeModal(e.target);
        }
    });
    
    function openModal(modal) {
        modal.style.display = 'block';
        document.body.style.overflow = 'hidden';
    }
    
    function closeModal(modal) {
        modal.style.display = 'none';
        document.body.style.overflow = 'auto';
    }
    
    function openAuthModal(activeTab) {
        openModal(authModal);
        switchTab(activeTab);
    }
    
    function switchTab(tabId) {
        tabButtons.forEach(button => {
            button.classList.remove('active');
        });
        
        tabContents.forEach(content => {
            content.classList.remove('active');
        });
        
        document.querySelector(`.tab-btn[data-tab="${tabId}"]`).classList.add('active');
        document.getElementById(`${tabId}-tab`).classList.add('active');
    }
    

    document.getElementById('login-form')?.addEventListener('submit', function(e) {
        e.preventDefault();
        const username = document.getElementById('login-username').value;
        localStorage.setItem('currentUser', username);
        
        const userNameElement = document.querySelector('#account-link .user-name');
        if (userNameElement) {
            userNameElement.textContent = username.split(' ')[0];
        }
        
        closeModal(authModal);
        window.location.href = 'account.html';
    });

    document.getElementById('register-form')?.addEventListener('submit', function(e) {
        e.preventDefault();
        const name = document.getElementById('register-name').value;
        localStorage.setItem('currentUser', name);
        
        const userNameElement = document.querySelector('#account-link .user-name');
        if (userNameElement) {
            userNameElement.textContent = name.split(' ')[0];
        }
        
        closeModal(authModal);
        window.location.href = 'account.html';
    });

    
    document.getElementById('recovery-form')?.addEventListener('submit', function(e) {
        e.preventDefault();
        alert('Код отправлен на ваш номер телефона!');
        closeModal(passwordRecoveryModal);
    });

    const animateOnScroll = function() {
        const elements = document.querySelectorAll('.service-card, .product-card');
        
        elements.forEach(element => {
            const elementPosition = element.getBoundingClientRect().top;
            const windowHeight = window.innerHeight;
            
            if (elementPosition < windowHeight - 100) {
                element.classList.add('animated');
            }
        });
    };
    
    window.addEventListener('scroll', animateOnScroll);
    animateOnScroll();
});




