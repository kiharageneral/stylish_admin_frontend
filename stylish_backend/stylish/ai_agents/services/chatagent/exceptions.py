class ChatValidationError(Exception):
    """Custom exception for input validation errors."""
    pass

class RateLimitExceededError(Exception):
    """Custom exception for when rate limits are hit."""
    pass

class DataFetchingError(Exception):
    """Custom exception for errors during data retrieval."""
    pass
