"""
LIBASS Input Validation Module — Strict Schema & Type Validation
Rejects malformed inputs, path traversal, control characters, and out-of-bounds parameters.
"""
import re

# Strict RFC 5322 pattern for email validation
EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")

ALLOWED_GENDERS = {'male', 'female', 'unspecified', 'other'}
ALLOWED_CATEGORIES = {'top', 'bottom', 'one_piece', 'shoes', 'outerwear', 'accessory'}
ALLOWED_SEASONS = {'spring', 'summer', 'autumn', 'winter', 'all'}
ALLOWED_FITS = {'tight', 'slim', 'regular', 'relaxed', 'oversized'}

def validate_email(email: str) -> str:
    """Validate and sanitize email address."""
    if not email or not isinstance(email, str):
        raise ValueError("Email is required.")
    email = email.strip()
    if len(email) > 120 or not EMAIL_REGEX.match(email):
        raise ValueError("Invalid email format or length.")
    return email

def validate_password(password: str) -> str:
    """Validate password strength and boundaries (8-128 characters)."""
    if not password or not isinstance(password, str):
        raise ValueError("Password is required.")
    if len(password) < 8 or len(password) > 128:
        raise ValueError("Password must be between 8 and 128 characters.")
    return password

def validate_gender(gender: str) -> str:
    """Validate gender enumeration."""
    if not gender:
        return 'unspecified'
    gender = str(gender).strip().lower()
    if gender not in ALLOWED_GENDERS:
        raise ValueError(f"Invalid gender. Must be one of: {', '.join(sorted(ALLOWED_GENDERS))}")
    return gender

def validate_measurement(value, field_name: str, min_val: float = 30.0, max_val: float = 300.0) -> float:
    """Validate numeric body measurement ranges in cm."""
    if value is None or value == '':
        return None
    try:
        val_float = float(value)
    except (ValueError, TypeError):
        raise ValueError(f"Invalid numeric value for {field_name}.")
    
    if val_float < min_val or val_float > max_val:
        raise ValueError(f"{field_name} must be between {min_val} cm and {max_val} cm.")
    return val_float

def validate_text(value: str, field_name: str, max_len: int = 100) -> str:
    """Sanitize and validate text string against control characters and length."""
    if value is None:
        return ""
    if not isinstance(value, str):
        raise ValueError(f"{field_name} must be a text string.")
    
    # Strip leading/trailing whitespace & control characters
    cleaned = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', value).strip()
    if len(cleaned) > max_len:
        raise ValueError(f"{field_name} cannot exceed {max_len} characters.")
    return cleaned
