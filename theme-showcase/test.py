#!/usr/bin/env python3
"""
Advanced Python example for testing Neovim theme colors.
This file includes various syntax elements to showcase highlighting.
"""

import os
import sys
import json
import asyncio
from typing import Dict, List, Optional, Union, Callable
from dataclasses import dataclass, field
from enum import Enum, auto
from pathlib import Path
from datetime import datetime, timedelta
import re

# Constants and global variables
VERSION = "2.1.0"
DEBUG = True
API_BASE_URL = "https://api.example.com/v1"
CONFIG_FILE = Path("~/.config/app.json").expanduser()

# Regular expressions
EMAIL_PATTERN = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
URL_PATTERN = re.compile(
    r"https?://(?:[-\w.])+(?:[:\d]+)?(?:/(?:[\w/_.])*)?(?:\?(?:[\w&=%.])*)?(?:#(?:\w)*)?"
)


class Status(Enum):
    """Enumeration for different status types."""

    PENDING = auto()
    PROCESSING = auto()
    COMPLETED = auto()
    FAILED = auto()


@dataclass
class User:
    """Represents a user in the system."""

    id: int
    username: str
    email: str
    created_at: datetime = field(default_factory=datetime.now)
    is_active: bool = True
    metadata: Dict[str, Union[str, int, float]] = field(default_factory=dict)

    def __post_init__(self):
        if not EMAIL_PATTERN.match(self.email):
            raise ValueError(f"Invalid email format: {self.email}")

    @property
    def age_days(self) -> int:
        """Calculate user age in days."""
        return (datetime.now() - self.created_at).days

    def to_dict(self) -> Dict:
        """Convert user to dictionary representation."""
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
            "created_at": self.created_at.isoformat(),
            "is_active": self.is_active,
            "metadata": self.metadata,
        }


class DatabaseConnection:
    """Mock database connection class with context manager support."""

    def __init__(self, connection_string: str, timeout: float = 30.0):
        self.connection_string = connection_string
        self.timeout = timeout
        self.is_connected = False
        self._transaction_count = 0

    async def __aenter__(self):
        """Async context manager entry."""
        await self.connect()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        await self.disconnect()
        if exc_type:
            print(f"Exception occurred: {exc_type.__name__}: {exc_val}")
        return False

    async def connect(self):
        """Establish database connection."""
        print(f"Connecting to: {self.connection_string}")
        await asyncio.sleep(0.1)  # Simulate connection delay
        self.is_connected = True

    async def disconnect(self):
        """Close database connection."""
        if self.is_connected:
            print("Disconnecting from database...")
            self.is_connected = False

    async def execute_query(
        self, query: str, params: Optional[Dict] = None
    ) -> List[Dict]:
        """Execute a database query."""
        if not self.is_connected:
            raise RuntimeError("Database not connected")

        # Simulate query execution
        print(f"Executing query: {query[:50]}...")
        if params:
            print(f"Parameters: {params}")

        await asyncio.sleep(0.05)  # Simulate query time
        return [{"id": 1, "result": "mock_data"}]


def validate_config(config: Dict) -> bool:
    """Validate configuration dictionary."""
    required_keys = ["database_url", "api_key", "debug"]

    for key in required_keys:
        if key not in config:
            print(f"❌ Missing required key: {key}")
            return False

    # Validate types
    if not isinstance(config["debug"], bool):
        print("❌ 'debug' must be a boolean")
        return False

    if not isinstance(config["database_url"], str):
        print("❌ 'database_url' must be a string")
        return False

    print("✅ Configuration is valid")
    return True


async def fetch_user_data(user_id: int, db: DatabaseConnection) -> Optional[User]:
    """Fetch user data from database."""
    try:
        query = """
        SELECT id, username, email, created_at, is_active, metadata
        FROM users 
        WHERE id = %(user_id)s AND is_active = %(active)s
        """

        params = {"user_id": user_id, "active": True}
        results = await db.execute_query(query, params)

        if not results:
            return None

        row = results[0]
        return User(
            id=row["id"],
            username=row.get("username", "unknown"),
            email=row.get("email", "no-email@example.com"),
            created_at=datetime.now(),
            is_active=row.get("is_active", True),
            metadata=json.loads(row.get("metadata", "{}")),
        )

    except Exception as e:
        print(f"🚨 Error fetching user {user_id}: {e}")
        return None


def process_users_batch(
    users: List[User],
    filter_func: Callable[[User], bool] = lambda u: u.is_active,
    transform_func: Optional[Callable[[User], Dict]] = None,
) -> List[Dict]:
    """Process a batch of users with optional filtering and transformation."""
    # Filter users
    filtered_users = [user for user in users if filter_func(user)]

    # Apply transformation
    if transform_func is None:
        transform_func = lambda u: u.to_dict()

    # List comprehension with conditional logic
    processed = [
        {
            **transform_func(user),
            "processed_at": datetime.now().isoformat(),
            "batch_id": f"batch_{hash(user.username) % 1000:03d}",
        }
        for user in filtered_users
        if user.age_days >= 0  # Additional filter
    ]

    return processed


class UserManager:
    """Manages user operations with caching and validation."""

    def __init__(self, db_connection: DatabaseConnection):
        self.db = db_connection
        self._cache: Dict[int, User] = {}
        self._stats = {"cache_hits": 0, "cache_misses": 0, "total_queries": 0}

    async def get_user(self, user_id: int, use_cache: bool = True) -> Optional[User]:
        """Get user by ID with optional caching."""
        # Check cache first
        if use_cache and user_id in self._cache:
            self._stats["cache_hits"] += 1
            return self._cache[user_id]

        # Fetch from database
        self._stats["cache_misses"] += 1
        self._stats["total_queries"] += 1

        user = await fetch_user_data(user_id, self.db)

        if user and use_cache:
            self._cache[user_id] = user

        return user

    def clear_cache(self):
        """Clear the user cache."""
        cache_size = len(self._cache)
        self._cache.clear()
        print(f"🧹 Cleared cache ({cache_size} entries)")

    @property
    def cache_stats(self) -> Dict[str, Union[int, float]]:
        """Get cache statistics."""
        total_requests = self._stats["cache_hits"] + self._stats["cache_misses"]
        hit_rate = (
            (self._stats["cache_hits"] / total_requests * 100)
            if total_requests > 0
            else 0.0
        )

        return {
            **self._stats,
            "hit_rate_percent": round(hit_rate, 2),
            "cache_size": len(self._cache),
        }


async def main():
    """Main application entry point."""
    print("🚀 Starting User Management System v" + VERSION)

    # Configuration loading
    config = {
        "database_url": "postgresql://user:pass@localhost:5432/testdb",
        "api_key": "sk-test-key-123456789",
        "debug": DEBUG,
        "batch_size": 100,
        "cache_ttl": 3600,
    }

    if not validate_config(config):
        sys.exit(1)

    # Create sample users for testing
    sample_users = [
        User(1, "alice_wonder", "alice@wonderland.com"),
        User(2, "bob_builder", "bob@construction.io"),
        User(3, "charlie_factory", "charlie@chocolate.com", is_active=False),
        User(4, "diana_prince", "diana@paradise.island"),
    ]

    # Database operations
    async with DatabaseConnection(config["database_url"]) as db:
        user_manager = UserManager(db)

        # Process users in batches
        active_users_only = lambda u: u.is_active and "@" in u.email
        add_summary = lambda u: {**u.to_dict(), "summary": f"User {u.username} ({u.id})"}

        processed_batch = process_users_batch(
            sample_users, filter_func=active_users_only, transform_func=add_summary
        )

        print(f"📊 Processed {len(processed_batch)} users")

        # Cache operations demo
        for user in sample_users[:2]:
            cached_user = await user_manager.get_user(user.id)
            if cached_user:
                print(f"👤 Retrieved: {cached_user.username} ({cached_user.email})")

        # Display statistics
        stats = user_manager.cache_stats
        print(f"📈 Cache Stats: {stats}")

    print("✅ Application completed successfully")


def fibonacci_generator(n: int):
    """Generator function for Fibonacci sequence."""
    a, b = 0, 1
    count = 0

    while count < n:
        yield a
        a, b = b, a + b
        count += 1


# Decorator example
def timing_decorator(func: Callable) -> Callable:
    """Decorator to measure function execution time."""

    def wrapper(*args, **kwargs):
        start_time = datetime.now()
        try:
            result = func(*args, **kwargs)
            return result
        finally:
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()
            print(f"⏱️  {func.__name__} took {duration:.4f} seconds")

    return wrapper


@timing_decorator
def complex_calculation(n: int) -> float:
    """Perform some complex calculation for timing demo."""
    result = sum(i**2 for i in range(n) if i % 2 == 0)
    return result / n if n > 0 else 0.0


# Lambda functions and functional programming
operations = {
    "square": lambda x: x**2,
    "cube": lambda x: x**3,
    "double": lambda x: x * 2,
    "is_even": lambda x: x % 2 == 0,
}


# Exception handling example
def safe_divide(a: float, b: float) -> Optional[float]:
    """Safely divide two numbers with proper error handling."""
    try:
        if b == 0:
            raise ZeroDivisionError("Cannot divide by zero")
        return a / b
    except (TypeError, ValueError) as e:
        print(f"⚠️  Type/Value error: {e}")
        return None
    except ZeroDivisionError as e:
        print(f"⚠️  Division error: {e}")
        return None
    except Exception as e:
        print(f"🚨 Unexpected error: {e}")
        return None
    finally:
        # This block always executes
        pass


if __name__ == "__main__":
    # Script execution
    print("=" * 50)
    print("PYTHON THEME TESTING EXAMPLE")
    print("=" * 50)

    # Run some quick demos
    print("\n🔢 Fibonacci sequence (first 10):")
    fib_numbers = list(fibonacci_generator(10))
    print(" -> " + ", ".join(map(str, fib_numbers)))

    print("\n🧮 Mathematical operations:")
    test_value = 5
    for name, operation in operations.items():
        result = operation(test_value)
        print(f" -> {name}({test_value}) = {result}")

    print("\n⚡ Complex calculation timing:")
    calc_result = complex_calculation(1000)
    print(f" -> Result: {calc_result:.2f}")

    print("\n➗ Safe division examples:")
    test_cases = [(10, 2), (15, 0), ("invalid", 5), (7, 3.5)]
    for a, b in test_cases:
        result = safe_divide(a, b)
        print(f" -> {a} ÷ {b} = {result}")

    # Run the main async function
    print("\n🔄 Running async main function:")
    asyncio.run(main())
