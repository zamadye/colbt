"""
Agent Suite SDK

Python SDK for Agent Suite API - Infrastructure for agents, by agents.
"""

from .client import AgentSuiteClient
from .models import Inbox, Message, SendMessageRequest

__version__ = "0.1.0"
__all__ = ["AgentSuiteClient", "Inbox", "Message", "SendMessageRequest"]
