import React, { useState, useEffect } from 'react';
import './CabinetForum.css';
import { FaChartLine, FaPen, FaSearch, FaFilter, FaThumbsUp, FaArrowLeft, FaPlus } from 'react-icons/fa';
import CreatePostModal from './CreatePostModal';
import {
  getPosts,
  createPost,
  toggleLike as serviceToggleLike,
  addComment,
  searchPosts
} from '../services/forumService';

const CabinetForum = () => {
  const [posts, setPosts] = useState([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedPost, setSelectedPost] = useState(null);
  const [newComment, setNewComment] = useState('');
  const [likedPosts, setLikedPosts] = useState(() => {
    const saved = localStorage.getItem('likedPosts');
    return saved ? JSON.parse(saved) : [];
  });

  useEffect(() => {
    setPosts(getPosts());
  }, []);

  useEffect(() => {
    localStorage.setItem('likedPosts', JSON.stringify(likedPosts));
  }, [likedPosts]);

  const handleCreatePost = (postData) => {
    createPost(postData);
    setPosts(getPosts());
  };

  const handleLike = (postId) => {
    let newLikedPosts;
    if (likedPosts.includes(postId)) {
      newLikedPosts = likedPosts.filter(id => id !== postId);
    } else {
      newLikedPosts = [...likedPosts, postId];
    }
    setLikedPosts(newLikedPosts);
    setPosts(serviceToggleLike(postId, likedPosts.includes(postId)));
  };

  const handleAddComment = (postId) => {
    if (newComment.trim()) {
      addComment(postId, newComment);
      setNewComment('');
      setPosts(getPosts());
    }
  };

  const handleSearch = (e) => {
    const query = e.target.value;
    setSearchQuery(query);
    setPosts(searchPosts(query));
  };
  
  const filteredPosts = searchQuery ? searchPosts(searchQuery) : getPosts();

  return (
    <div className="forum">
      <div className="forum-header">
        <button className="forum-back-btn" onClick={() => window.history.back()}>
          <FaArrowLeft />
        </button>
        <div className="forum-title">
          <FaChartLine className="forum-title-icon" />
          <h1>Форум прогнозов</h1>
        </div>
        <button className="forum-new-post-btn" onClick={() => setIsModalOpen(true)}>
          <FaPlus />
        </button>
      </div>

      <div className="forum-tools">
        <div className="search-bar">
          <FaSearch className="search-icon" />
          <input
            type="text"
            placeholder="Поиск по валюте, автору или прогнозу..."
            value={searchQuery}
            onChange={handleSearch}
          />
        </div>
      </div>

      <div className="forum-content">
        {filteredPosts.map(post => {
          const isLiked = likedPosts.includes(post.id);
          return (
            <div key={post.id} className="forum-post">
              <div className="post-header">
                <div className="post-author">
                  <div className="author-avatar">
                    {post.author.avatar}
                  </div>
                  <div className="author-info">
                    <div className="author-name">{post.author.name}</div>
                    <div className="author-role">{post.author.role}</div>
                  </div>
                </div>
                <div className="post-date">{post.date}</div>
              </div>

              <div className="post-content">
                <div className="post-prediction">
                  <div className="prediction-pair">{post.currency}</div>
                  <div className={`prediction-type ${post.prediction.toLowerCase()}`}>
                    {post.prediction}
                  </div>
                </div>
                <div className="prediction-confidence">
                  {post.confidence}% уверенность
                </div>
                {post.description && (
                  <div className="post-description">
                    {post.description}
                  </div>
                )}
              </div>

              <div className="post-footer">
                <div className="post-stats">
                  <button 
                    className={`stat-btn like-btn ${isLiked ? 'liked' : ''}`} 
                    onClick={() => handleLike(post.id)}
                  >
                    <FaThumbsUp /> {post.likes}
                  </button>
                  <button 
                    className="stat-btn"
                    onClick={() => setSelectedPost(selectedPost === post.id ? null : post.id)}
                  >
                    💬 {post.comments.length}
                  </button>
                </div>
                <button className="post-details-btn">
                  Подробнее
                </button>
              </div>

              {selectedPost === post.id && (
                <div className="comments-section">
                  <div className="comments-list">
                    {post.comments.map(comment => (
                      <div key={comment.id} className="comment">
                        <div className="comment-author">{comment.author}</div>
                        <div className="comment-text">{comment.text}</div>
                        {comment.date && (
                          <div className="comment-date">{comment.date}</div>
                        )}
                      </div>
                    ))}
                  </div>
                  <div className="add-comment">
                    <input
                      type="text"
                      placeholder="Написать комментарий..."
                      value={newComment}
                      onChange={(e) => setNewComment(e.target.value)}
                      onKeyPress={(e) => e.key === 'Enter' && handleAddComment(post.id)}
                    />
                    <button onClick={() => handleAddComment(post.id)}>
                      Отправить
                    </button>
                  </div>
                </div>
              )}
            </div>
          )
        })}
      </div>

      <CreatePostModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleCreatePost}
      />
    </div>
  );
};

export default CabinetForum; 