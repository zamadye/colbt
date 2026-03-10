"""
Agent Suite SDK - Python SDK for Agent Suite API
"""

from setuptools import setup, find_packages
from pathlib import Path

# Read README
readme_file = Path(__file__).parent / "README.md"
long_description = readme_file.read_text(encoding="utf-8")

setup(
    name="agent-suite-sdk",
    version="0.1.0",
    author="Agent Suite Contributors",
    author_email="kimiclaw_dev",
    description="Python SDK for Agent Suite API - Infrastructure for agents, by agents",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/dmb4086/agent-suite",
    project_urls={
        "Bug Reports": "https://github.com/dmb4086/agent-suite/issues",
        "Source": "https://github.com/dmb4086/agent-suite",
    },
    packages=find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Typing :: Typed",
    ],
    python_requires=">=3.8",
    install_requires=[
        "httpx>=0.24.0",
        "pydantic>=2.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-asyncio>=0.21.0",
            "black>=23.0.0",
            "mypy>=1.0.0",
        ],
    },
    keywords="api sdk email agent async httpx",
)
