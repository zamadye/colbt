"""
Pydantic models for Agent Suite SDK
"""

from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime


class Inbox(BaseModel):
    """Represents an email inbox"""

    id: str
    email_address: EmailStr
    created_at: datetime
    is_active: bool = True


class InboxWithApiKey(Inbox):
    """Inbox response including API key (only returned on creation)"""

    api_key: str


class Message(BaseModel):
    """Represents an email message"""

    id: str
    sender: EmailStr
    recipient: EmailStr
    subject: str
    body_text: str
    body_html: Optional[str] = None
    is_read: bool = False
    received_at: datetime


class MessageList(BaseModel):
    """Paginated list of messages"""

    total: int
    messages: List[Message]


class SendMessageRequest(BaseModel):
    """Request to send an email"""

    to: EmailStr
    subject: str
    body: str
    html_body: Optional[str] = None


class SendMessageResponse(BaseModel):
    """Response from sending an email"""

    status: str
    message_id: str
    to: EmailStr


class HealthCheck(BaseModel):
    """Health check response"""

    status: str
    service: str
