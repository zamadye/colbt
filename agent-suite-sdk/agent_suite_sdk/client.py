"""
Agent Suite API Client

Async Python client for interacting with Agent Suite API
"""

import httpx
from typing import Optional, List
from .models import (
    Inbox,
    InboxWithApiKey,
    Message,
    MessageList,
    SendMessageRequest,
    SendMessageResponse,
    HealthCheck,
)


class AgentSuiteClientError(Exception):
    """Base exception for Agent Suite client errors"""

    pass


class AuthenticationError(AgentSuiteClientError):
    """Raised when API key authentication fails"""

    pass


class APIError(AgentSuiteClientError):
    """Raised when API request fails"""

    def __init__(self, message: str, status_code: Optional[int] = None):
        self.status_code = status_code
        super().__init__(message)


class AgentSuiteClient:
    """
    Async client for Agent Suite API

    Example:
        ```python
        import asyncio
        from agent_suite_sdk import AgentSuiteClient

        async def main():
            # Create inbox
            client = AgentSuiteClient(base_url="http://localhost:8000")
            inbox = await client.create_inbox()
            print(f"Email: {inbox.email_address}")
            print(f"API Key: {inbox.api_key}")

            # Send email
            await client.send_email(
                api_key=inbox.api_key,
                to="recipient@example.com",
                subject="Hello from Agent",
                body="This was sent programmatically"
            )

            # List messages
            messages = await client.list_messages(api_key=inbox.api_key)
            print(f"Received {messages.total} messages")

        asyncio.run(main())
        ```
    """

    def __init__(
        self,
        base_url: str = "http://localhost:8000",
        timeout: float = 30.0,
        max_retries: int = 3,
    ):
        """
        Initialize the client

        Args:
            base_url: Base URL of Agent Suite API
            timeout: Request timeout in seconds
            max_retries: Maximum number of retry attempts
        """
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.max_retries = max_retries

        # Configure httpx client with retry logic
        limits = httpx.Limits(max_keepalive_connections=5, max_connections=10)
        self._client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=timeout,
            limits=limits,
        )

    async def __aenter__(self):
        """Async context manager entry"""
        await self._client.__aenter__()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        await self._client.__aexit__(exc_type, exc_val, exc_tb)

    async def close(self):
        """Close the HTTP client"""
        await self._client.aclose()

    def _get_headers(self, api_key: Optional[str] = None) -> dict:
        """Build request headers with optional authorization"""
        headers = {"Content-Type": "application/json"}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"
        return headers

    async def _request(
        self,
        method: str,
        path: str,
        api_key: Optional[str] = None,
        **kwargs,
    ) -> dict:
        """
        Make HTTP request with retry logic

        Args:
            method: HTTP method
            path: API path
            api_key: Optional API key for authorization
            **kwargs: Additional arguments for httpx

        Returns:
            Parsed JSON response

        Raises:
            AuthenticationError: If authentication fails
            APIError: If request fails after retries
        """
        headers = self._get_headers(api_key)
        url = f"{self.base_url}{path}"

        last_error = None
        for attempt in range(self.max_retries):
            try:
                response = await self._client.request(
                    method=method,
                    url=path,
                    headers=headers,
                    **kwargs,
                )

                response.raise_for_status()
                return response.json()

            except httpx.HTTPStatusError as e:
                last_error = e

                if e.response.status_code == 401:
                    raise AuthenticationError("Invalid API key")

                # Retry on server errors
                if e.response.status_code >= 500 and attempt < self.max_retries - 1:
                    continue

                raise APIError(
                    f"API request failed: {e.response.status_code}",
                    status_code=e.response.status_code,
                )

            except httpx.RequestError as e:
                last_error = e

                # Retry on connection errors
                if attempt < self.max_retries - 1:
                    continue

                raise APIError(f"Request failed: {str(e)}")

        # Should not reach here, but just in case
        raise APIError(f"Request failed after {self.max_retries} retries")

    async def health_check(self) -> HealthCheck:
        """
        Check API health status

        Returns:
            HealthCheck response
        """
        data = await self._request("GET", "/health")
        return HealthCheck(**data)

    async def create_inbox(self) -> InboxWithApiKey:
        """
        Create a new email inbox

        Returns:
            Inbox with email address and API key

        Raises:
            APIError: If inbox creation fails
        """
        data = await self._request("POST", "/v1/inboxes")
        return InboxWithApiKey(**data)

    async def get_inbox(self, api_key: str) -> Inbox:
        """
        Get details of authenticated inbox

        Args:
            api_key: Your inbox API key

        Returns:
            Inbox details

        Raises:
            AuthenticationError: If API key is invalid
        """
        data = await self._request("GET", "/v1/inboxes/me", api_key=api_key)
        return Inbox(**data)

    async def send_email(
        self,
        api_key: str,
        to: str,
        subject: str,
        body: str,
        html_body: Optional[str] = None,
    ) -> SendMessageResponse:
        """
        Send an email using AWS SES

        Args:
            api_key: Your inbox API key
            to: Recipient email address
            subject: Email subject
            body: Plain text body
            html_body: Optional HTML body

        Returns:
            Send response with message ID

        Raises:
            AuthenticationError: If API key is invalid
            APIError: If sending fails
        """
        payload = {
            "to": to,
            "subject": subject,
            "body": body,
        }

        if html_body:
            payload["html_body"] = html_body

        data = await self._request(
            "POST",
            "/v1/inboxes/me/send",
            api_key=api_key,
            json=payload,
        )

        return SendMessageResponse(**data)

    async def list_messages(
        self,
        api_key: str,
        skip: int = 0,
        limit: int = 50,
        unread_only: bool = False,
    ) -> MessageList:
        """
        List received messages

        Args:
            api_key: Your inbox API key
            skip: Number of messages to skip
            limit: Maximum messages to return
            unread_only: Only return unread messages

        Returns:
            Paginated message list

        Raises:
            AuthenticationError: If API key is invalid
        """
        params = {
            "skip": skip,
            "limit": limit,
            "unread_only": unread_only,
        }

        data = await self._request(
            "GET",
            "/v1/inboxes/me/messages",
            api_key=api_key,
            params=params,
        )

        return MessageList(**data)

    async def receive_webhook(
        self,
        sender: str,
        recipient: str,
        subject: str = "",
        body_plain: str = "",
        body_html: str = "",
        message_id: str = "",
    ) -> dict:
        """
        Simulate receiving a Mailgun webhook

        Note: This is primarily used for testing. In production,
        Mailgun will POST directly to your webhook endpoint.

        Args:
            sender: Sender email address
            recipient: Recipient email address
            subject: Email subject
            body_plain: Plain text body
            body_html: HTML body
            message_id: Message ID

        Returns:
            Webhook response
        """
        payload = {
            "sender": sender,
            "recipient": recipient,
            "subject": subject,
            "body-plain": body_plain,
            "body-html": body_html,
            "Message-Id": message_id,
        }

        # Use form data for webhook
        return await self._request(
            "POST",
            "/v1/webhooks/mailgun",
            data=payload,
        )


# Convenience function for quick usage
async def create_client(
    base_url: str = "http://localhost:8000",
) -> AgentSuiteClient:
    """
    Create and return an Agent Suite client

    Args:
        base_url: Base URL of Agent Suite API

    Returns:
        Initialized AgentSuiteClient
    """
    return AgentSuiteClient(base_url=base_url)
