"""
Django settings for nyota_bank project.
Настроено для Railway деплоя.
"""

from pathlib import Path
import os
import dj_database_url
from decouple import config

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Загружаем .env только в локальной разработке
if os.path.exists(BASE_DIR / '.env'):
    from dotenv import load_dotenv
    load_dotenv(BASE_DIR / '.env')

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config('SECRET_KEY', default='django-insecure-change-me-in-production')
EXCHANGE_RATE_API_KEY = config('EXCHANGE_RATE_API_KEY', default='')

# OpenAI API Configuration
OPENAI_API_KEY = config('OPENAI_API_KEY', default='')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = config('DEBUG', default=False, cast=bool)

# Railway автоматически предоставляет RAILWAY_STATIC_URL
RAILWAY_STATIC_URL = config('RAILWAY_STATIC_URL', default='')
ALLOWED_HOSTS = ['localhost', '127.0.0.1', 'testserver']

# Добавляем Railway домены
if RAILWAY_STATIC_URL:
    ALLOWED_HOSTS.append(RAILWAY_STATIC_URL.replace('https://', '').replace('http://', ''))

# В продакшене разрешаем все хосты (Railway использует динамические домены)
if not DEBUG:
    ALLOWED_HOSTS = ['*']

# Application definition
AUTHENTICATION_BACKENDS = [
    # 'api.backends.PhoneNumberBackend', # Temporarily disabled for debugging
    'django.contrib.auth.backends.ModelBackend',
]

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'api',
    'rest_framework',
    'rest_framework.authtoken',
    # 'corsheaders',  # Temporarily disabled for debugging
]

AUTH_USER_MODEL = 'api.User'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    )
}

MIDDLEWARE = [
    # 'corsheaders.middleware.CorsMiddleware',  # Temporarily disabled for debugging
    'django.middleware.security.SecurityMiddleware',
    # 'whitenoise.middleware.WhiteNoiseMiddleware',  # Temporarily disabled for debugging
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# CORS настройки для веб-фронтенда
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",  # React dev server
    "http://127.0.0.1:3000",
    "https://localhost:3000",
]

# В продакшене можно добавить домен фронтенда
if not DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True  # Временно для тестирования

ROOT_URLCONF = 'nyota_bank.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'nyota_bank.wsgi.application'

# Database
# Railway автоматически предоставляет DATABASE_URL
DATABASE_URL = config('DATABASE_URL', default='')

if DATABASE_URL:
    # Используем Railway PostgreSQL
    DATABASES = {
        'default': dj_database_url.parse(DATABASE_URL)
    }
else:
    # Локальная разработка
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": config("DB_NAME", default="nyota_bank"),
            "USER": config("DB_USER", default="postgres"),
            "PASSWORD": config("DB_PASSWORD", default=""),
            "HOST": config("DB_HOST", default="localhost"),
            "PORT": config("DB_PORT", default="5432"),
        }
    }

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# WhiteNoise настройки для статических файлов
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Media files (uploaded by users)
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Custom application settings
MORTGAGE_BASE_RATE = 20.0

# Безопасность для продакшена
if not DEBUG:
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True 