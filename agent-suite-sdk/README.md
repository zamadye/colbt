# Agent Suite SDK

> Python SDK for Agent Suite API - Infrastructure for agents, by agents.

[![PyPI](https://img.shields.io/pypi/v/agent-suite-sdk)](https://pypi.org/project/agent-suite-sdk/)
[![Python](https://img.shields.io/pypi/pyversions/agent-suite-sdk)](https://pypi.org/project/agent-suite-sdk/)

## Installation

```bash
pip install agent-suite-sdk
```

## Quick Start

```python
import asyncio
from agent_suite_sdk import AgentSuiteClient

async def main():
    # Create client
    client = AgentSuiteClient(base_url="http://localhost:8000")

    try:
        # Create an inbox
        inbox = await client.create_inbox()
        print(f"✅ Email: {inbox.email_address}")
        print(f"✅ API Key: {inbox.api_key}")

        # Send an email
        response = await client.send_email(
            api_key=inbox.api_key,
            to="recipient@example.com",
            subject="Hello from Agent",
            body="This was sent programmatically!"
        )
        print(f"✅ Sent: {response.message_id}")

        # List messages
        messages = await client.list_messages(api_key=inbox.api_key)
        print(f"✅ Received {messages.total} messages")

    finally:
        await client.close()

asyncio.run(main())
```

## Features

- ✅ **Async-first** - Built on `httpx` for async operations
- ✅ **Type-safe** - Pydantic models for request/response validation
- ✅ **Retry logic** - Automatic retries on failures
- ✅ **Error handling** - Clear exception types
- ✅ **PEP 8 compliant** - Clean, readable code

## API Reference

### AgentSuiteClient

Main client for interacting with Agent Suite API.

#### Methods

##### `create_inbox()`
Create a new email inbox with unique address and API key.

```python
inbox = await client.create_inbox()
# InboxWithApiKey(
#     id="uuid",
#     email_address="abc123@agents.dev",
#     api_key="as_xxx",
#     created_at=datetime(...),
#     is_active=True
# )
```

##### `send_email(api_key, to, subject, body, html_body=None)`
Send an email using AWS SES.

```python
response = await client.send_email(
    api_key=inbox.api_key,
    to="recipient@example.com",
    subject="Hello from Agent",
    body="Plain text body",
    html_body="<p>HTML body</p>"
)
# SendMessageResponse(status="sent", message_id="...", to="...")
```

##### `list_messages(api_key, skip=0, limit=50, unread_only=False)`
List received messages.

```python
messages = await client.list_messages(
    api_key=inbox.api_key,
    limit=10,
    unread_only=True
)
# MessageList(total=42, messages=[Message(...), ...])
```

##### `get_inbox(api_key)`
Get details of authenticated inbox.

```python
inbox = await client.get_inbox(api_key=inbox.api_key)
# Inbox(...)
```

##### `health_check()`
Check API health status.

```python
health = await client.health_check()
# HealthCheck(status="ok", service="agent-suite")
```

## Error Handling

```python
from agent_suite_sdk import AgentSuiteClient, AuthenticationError, APIError

try:
    inbox = await client.create_inbox()
except AuthenticationError:
    print("❌ Invalid API key")
except APIError as e:
    print(f"❌ API error: {e}")
```

## Advanced Usage

### Custom Configuration

```python
client = AgentSuiteClient(
    base_url="https://api.agents.dev",
    timeout=60.0,
    max_retries=5
)
```

### Context Manager

```python
async with AgentSuiteClient() as client:
    inbox = await client.create_inbox()
    # Auto-closes on exit
```

### Batch Operations

```python
# Create multiple inboxes
inboxes = []
async with AgentSuiteClient() as client:
    for i in range(5):
        inbox = await client.create_inbox()
        inboxes.append(inbox)

print(f"Created {len(inboxes)} inboxes")
```

## Examples

See the [`examples/`](examples/) directory for more examples:

- `examples/create_inbox.py` - Create an inbox
- `examples/send_email.py` - Send emails
- `examples/list_messages.py` - List and filter messages
- `examples/async_batch.py` - Batch operations

## Development

```bash
# Install dependencies
pip install -e ".[dev]"

# Run tests
pytest

# Format code
black agent_suite_sdk
```

## License

MIT

## Links

- [Agent Suite API](https://github.com/dmb4086/agent-suite)
- [OpenAPI Spec](https://github.com/dmb4086/agent-suite/blob/main/openapi.yaml)
- [PyPI Package](https://pypi.org/project/agent-suite-sdk/)
