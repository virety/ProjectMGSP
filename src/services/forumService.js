// Имитация API с использованием localStorage
const STORAGE_KEY = 'forum_posts';

const getInitialPosts = () => [
  {
    id: 1,
    author: {
      name: 'Вадим Семибратов',
      role: 'Брокер',
      avatar: '📊'
    },
    currency: 'EUR/RUB',
    prediction: 'Рост',
    confidence: 70,
    date: '12.06.2025',
    likes: 0,
    comments: [],
    description: 'Ожидается укрепление евро на фоне экономических показателей ЕС.'
  },
  {
    id: 2,
    author: {
      name: 'Анна Петрова',
      role: 'Аналитик',
      avatar: '📈'
    },
    currency: 'USD/RUB',
    prediction: 'Падение',
    confidence: 85,
    date: '12.06.2025',
    likes: 12,
    comments: [
      { id: 1, author: 'Иван Иванов', text: 'Полностью согласен с прогнозом!' },
      { id: 2, author: 'Петр Петров', text: 'Интересный анализ, спасибо.' }
    ],
    description: 'На основе технического анализа ожидается коррекция курса.'
  }
];

// Инициализация хранилища при первом запуске
const initializeStorage = () => {
  if (!localStorage.getItem(STORAGE_KEY)) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(getInitialPosts()));
  }
};

// Получение всех постов
export const getPosts = () => {
  initializeStorage();
  return JSON.parse(localStorage.getItem(STORAGE_KEY));
};

// Создание нового поста
export const createPost = (postData) => {
  const posts = getPosts();
  const newPost = {
    id: Date.now(),
    author: {
      name: 'Текущий пользователь', // В реальном приложении брать из авторизации
      role: 'Пользователь',
      avatar: '👤'
    },
    date: new Date().toLocaleDateString(),
    likes: 0,
    comments: [],
    ...postData
  };
  
  posts.unshift(newPost);
  localStorage.setItem(STORAGE_KEY, JSON.stringify(posts));
  return newPost;
};

// Добавление лайка к посту
export const toggleLike = (postId, isCurrentlyLiked) => {
  const posts = getPosts();
  const postIndex = posts.findIndex(p => p.id === postId);
  if (postIndex !== -1) {
    if (isCurrentlyLiked) {
      posts[postIndex].likes -= 1;
    } else {
      posts[postIndex].likes += 1;
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(posts));
  }
  return posts; // Возвращаем обновленный список
};

// Добавление комментария
export const addComment = (postId, comment) => {
  const posts = getPosts();
  const post = posts.find(p => p.id === postId);
  if (post) {
    const newComment = {
      id: Date.now(),
      author: 'Текущий пользователь', // В реальном приложении брать из авторизации
      text: comment,
      date: new Date().toLocaleDateString()
    };
    post.comments.push(newComment);
    post.comments = post.comments || [];
    localStorage.setItem(STORAGE_KEY, JSON.stringify(posts));
    return newComment;
  }
  return null;
};

// Поиск постов
export const searchPosts = (query) => {
  const posts = getPosts();
  const lowercaseQuery = query.toLowerCase();
  
  return posts.filter(post => 
    post.currency.toLowerCase().includes(lowercaseQuery) ||
    post.prediction.toLowerCase().includes(lowercaseQuery) ||
    post.description.toLowerCase().includes(lowercaseQuery) ||
    post.author.name.toLowerCase().includes(lowercaseQuery)
  );
};

// Фильтрация постов
export const filterPosts = (filters) => {
  let posts = getPosts();
  
  if (filters.currency) {
    posts = posts.filter(post => post.currency === filters.currency);
  }
  
  if (filters.prediction) {
    posts = posts.filter(post => post.prediction === filters.prediction);
  }
  
  if (filters.minConfidence) {
    posts = posts.filter(post => post.confidence >= filters.minConfidence);
  }
  
  return posts;
}; 