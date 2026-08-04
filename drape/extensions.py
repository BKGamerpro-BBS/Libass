"""
LIBASS Flask Extensions — Shared Limiter Instance
Decouples Limiter from app.py to prevent circular import dependencies across blueprints.
"""
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
