import requests
import json
from django.conf import settings
from typing import List, Dict, Optional
from .models import User, Card, Transaction
from decimal import Decimal
import logging

logger = logging.getLogger(__name__)

# This file can be used for other non-AI services in the future
# AI services have been moved to services/ai_service.py 