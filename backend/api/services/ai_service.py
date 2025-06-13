"""
AI Chat service for handling AI assistant functionality
"""
import os
import time
import json
import logging
import requests
from typing import List, Dict, Optional
from django.conf import settings
from django.utils import timezone
from ..models import User, AIChat, AIChatMessage

logger = logging.getLogger(__name__)


class OpenAIService:
    """Service for interacting with OpenAI API"""
    
    def __init__(self):
        self.api_key = os.getenv('OPENAI_API_KEY')
        self.base_url = "https://api.openai.com/v1"
        self.model = "gpt-3.5-turbo"
        self.timeout = 30
    
    def get_system_prompt(self, user: User) -> str:
        """Get system prompt with user context"""
        context = self.get_user_context(user)
        
        return f"""Вы - банковский ассистент Nyota Bank. Вы помогаете клиентам с банковскими услугами.

Информация о клиенте:
{context}

Инструкции:
- Отвечайте на русском языке
- Будьте вежливы и профессиональны
- Предоставляйте точную информацию о банковских услугах
- Если не знаете ответ, честно скажите об этом
- Помогайте с вопросами о картах, переводах, кредитах, депозитах
- Не предоставляйте конфиденциальную информацию без подтверждения
"""

    def get_user_context(self, user: User) -> str:
        """Get user context for AI"""
        context_service = BankingContextService()
        
        context = f"""
Имя: {user.get_full_name()}
Телефон: {user.phone_number}

Баланс карт:
{context_service.get_balance_summary(user)}

Недавние транзакции:
{context_service.get_recent_transactions(user)}
"""
        return context.strip()

    def chat_completion(
        self, 
        messages: List[Dict[str, str]], 
        user: User,
        chat: Optional[AIChat] = None
    ) -> Dict:
        """
        Send chat completion request to OpenAI API
        Returns dict with success, message, and metadata
        """
        if not self.api_key:
            logger.error("OpenAI API key not configured")
            return {
                'success': False,
                'error': 'AI сервис временно недоступен.',
                'processing_time': 0
            }
        
        start_time = time.time()
        
        try:
            # Prepare messages with system prompt
            system_prompt = self.get_system_prompt(user)
            api_messages = [{"role": "system", "content": system_prompt}] + messages
            
            # Prepare request
            headers = {
                'Authorization': f'Bearer {self.api_key}',
                'Content-Type': 'application/json'
            }
            
            payload = {
                'model': self.model,
                'messages': api_messages,
                'max_tokens': 500,
                'temperature': 0.7,
                'user': str(user.id)
            }
            
            # Make request
            response = requests.post(
                f"{self.base_url}/chat/completions",
                headers=headers,
                json=payload,
                timeout=self.timeout
            )
            
            processing_time = time.time() - start_time
            
            if response.status_code == 200:
                data = response.json()
                
                message_content = data['choices'][0]['message']['content']
                tokens_used = data.get('usage', {}).get('total_tokens', 0)
                
                logger.info(f"OpenAI request successful. Tokens used: {tokens_used}")
                
                return {
                    'success': True,
                    'message': message_content,
                    'tokens_used': tokens_used,
                    'model_used': self.model,
                    'processing_time': processing_time
                }
            
            elif response.status_code == 429:
                logger.error("OpenAI rate limit exceeded")
                return {
                    'success': False,
                    'error': 'Слишком много запросов. Попробуйте позже.',
                    'processing_time': processing_time
                }
            
            elif response.status_code == 401:
                logger.error("OpenAI authentication failed")
                return {
                    'success': False,
                    'error': 'Ошибка аутентификации AI сервиса.',
                    'processing_time': processing_time
                }
            
            elif response.status_code == 403:
                logger.error("OpenAI access forbidden - region not supported")
                return {
                    'success': False,
                    'error': 'AI сервис недоступен в вашем регионе.',
                    'processing_time': processing_time
                }
            
            else:
                logger.error(f"OpenAI API error: {response.status_code} - {response.text}")
                return {
                    'success': False,
                    'error': 'Ошибка AI сервиса. Попробуйте позже.',
                    'processing_time': processing_time
                }
                
        except requests.exceptions.Timeout:
            logger.error("OpenAI request timeout")
            return {
                'success': False,
                'error': 'Превышено время ожидания ответа.',
                'processing_time': time.time() - start_time
            }
            
        except requests.exceptions.ConnectionError:
            logger.error("OpenAI connection error")
            return {
                'success': False,
                'error': 'Ошибка подключения к AI сервису.',
                'processing_time': time.time() - start_time
            }
            
        except Exception as e:
            logger.error(f"Unexpected error in OpenAI service: {e}")
            return {
                'success': False,
                'error': 'Произошла ошибка. Попробуйте позже.',
                'processing_time': time.time() - start_time
            }


class AIChatService:
    """Service for managing AI chat sessions"""
    
    def __init__(self):
        self.openai_service = OpenAIService()
    
    def get_or_create_chat(self, user: User, chat_id: Optional[str] = None) -> AIChat:
        """Get existing chat or create new one"""
        if chat_id:
            try:
                return AIChat.objects.get(id=chat_id, user=user, is_active=True)
            except AIChat.DoesNotExist:
                pass
        
        # Create new chat
        chat = AIChat.objects.create(user=user)
        
        # Add welcome message
        AIChatMessage.objects.create(
            chat=chat,
            role='assistant',
            content=f"Привет, {user.first_name}! Я ваш банковский ассистент. Чем могу помочь?"
        )
        
        return chat
    
    def add_user_message(self, chat: AIChat, content: str) -> AIChatMessage:
        """Add user message to chat"""
        return AIChatMessage.objects.create(
            chat=chat,
            role='user',
            content=content
        )
    
    def get_chat_messages_for_ai(self, chat: AIChat, limit: int = 10) -> List[Dict[str, str]]:
        """Get recent chat messages formatted for OpenAI API"""
        messages = chat.messages.filter(role__in=['user', 'assistant']).order_by('-created_at')[:limit]
        
        # Reverse to get chronological order
        messages = list(reversed(messages))
        
        return [
            {
                "role": msg.role,
                "content": msg.content
            }
            for msg in messages
        ]
    
    def process_user_message(self, chat: AIChat, user_message: str) -> AIChatMessage:
        """Process user message and get AI response (synchronous version)"""
        # Add user message
        user_msg = self.add_user_message(chat, user_message)
        
        # Get chat history for context
        messages = self.get_chat_messages_for_ai(chat)
        
        # Get AI response
        ai_response = self.openai_service.chat_completion(
            messages=messages,
            user=chat.user,
            chat=chat
        )
        
        if ai_response['success']:
            # Create assistant message
            assistant_msg = AIChatMessage.objects.create(
                chat=chat,
                role='assistant',
                content=ai_response['message'],
                tokens_used=ai_response.get('tokens_used'),
                model_used=ai_response.get('model_used'),
                processing_time=ai_response.get('processing_time')
            )
            
            # Update chat title if not set
            if not chat.title and user_message:
                chat.title = user_message[:50] + ('...' if len(user_message) > 50 else '')
                chat.save()
            
            # Update chat timestamp
            chat.save()  # This will update updated_at
            
            return assistant_msg
        else:
            # Create error message
            error_msg = AIChatMessage.objects.create(
                chat=chat,
                role='assistant',
                content=ai_response['error'],
                processing_time=ai_response.get('processing_time')
            )
            return error_msg
    
    def get_user_chats(self, user: User) -> List[AIChat]:
        """Get user's active chats"""
        return list(user.ai_chats.filter(is_active=True).order_by('-updated_at'))
    
    def delete_chat(self, chat: AIChat) -> bool:
        """Soft delete chat"""
        chat.is_active = False
        chat.save()
        return True


class BankingContextService:
    """Service for providing banking context to AI"""
    
    @staticmethod
    def get_balance_summary(user: User) -> str:
        """Get user's balance summary"""
        cards = user.cards.filter(is_active=True)
        if not cards.exists():
            return "У вас нет активных карт."
        
        total_balance = sum(card.balance for card in cards)
        card_count = cards.count()
        
        summary = f"Общий баланс: {total_balance} руб. на {card_count} карт(ах).\n"
        
        for card in cards:
            card_name = card.card_name or f"Карта {card.card_number[-4:]}"
            summary += f"- {card_name}: {card.balance} руб.\n"
        
        return summary.strip()
    
    @staticmethod
    def get_recent_transactions(user: User, limit: int = 5) -> str:
        """Get recent transactions summary"""
        transactions = user.transactions.order_by('-timestamp')[:limit]
        
        if not transactions.exists():
            return "Нет недавних транзакций."
        
        summary = f"Последние {len(transactions)} транзакций:\n"
        
        for tx in transactions:
            tx_type = "+" if tx.transaction_type == 1 else "-"
            date_str = tx.timestamp.strftime("%d.%m.%Y")
            summary += f"- {date_str}: {tx.title} {tx_type}{tx.amount} руб.\n"
        
        return summary.strip() 