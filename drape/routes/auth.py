import os
import uuid
from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash
from flask_login import login_user, logout_user, login_required, current_user
from models import db, User, Profile
from validators import validate_email, validate_password, validate_gender
from extensions import limiter

auth_bp = Blueprint('auth', __name__)


AUTH_LIMIT = os.environ.get("RATELIMIT_AUTH", "10 per minute;30 per hour")

@auth_bp.route('/register', methods=['POST'])
@limiter.limit(AUTH_LIMIT)
def register():
    data = request.json or {}
    try:
        email = validate_email(data.get('email'))
        password = validate_password(data.get('password'))
        gender = validate_gender(data.get('gender', 'unspecified'))
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

    if User.query.filter_by(email=email).first():
        return jsonify({"error": "Email already registered"}), 400

    user = User(
        id=str(uuid.uuid4()),
        email=email,
        password_hash=generate_password_hash(password),
        gender=gender
    )
    db.session.add(user)
    
    # Initialize profile record for user
    profile = Profile(user_id=user.id)
    db.session.add(profile)
    
    db.session.commit()

    login_user(user)
    return jsonify({"success": True, "user_id": user.id, "email": email, "gender": gender})

@auth_bp.route('/login', methods=['POST'])
@limiter.limit(AUTH_LIMIT)
def login():
    data = request.json or {}
    try:
        email = validate_email(data.get('email'))
        password = validate_password(data.get('password'))
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

    user = User.query.filter_by(email=email).first()
    if user and user.check_password(password):
        login_user(user)
        return jsonify({"success": True, "user_id": user.id, "email": user.email, "gender": user.gender})

    return jsonify({"error": "Invalid email or password"}), 401

@auth_bp.route('/logout', methods=['POST'])
@login_required
def logout():
    logout_user()
    return jsonify({"success": True})

@auth_bp.route('/session', methods=['GET'])
def check_session():
    if current_user.is_authenticated:
        return jsonify({"authenticated": True, "email": current_user.email, "gender": getattr(current_user, 'gender', 'unspecified')})
    return jsonify({"authenticated": False}), 401
