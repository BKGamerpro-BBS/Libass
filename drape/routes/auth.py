import uuid
from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash
from flask_login import login_user, logout_user, login_required, current_user
from models import db, User, Profile


auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    gender = data.get('gender', 'unspecified')
    if not email or not password:
        return jsonify({"error": "Missing email or password"}), 400

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
def login():
    data = request.json
    email = data.get('email')
    password = data.get('password')

    user = User.query.filter_by(email=email).first()
    if user and user.check_password(password):
        login_user(user)
        return jsonify({"success": True, "user_id": user.id, "email": user.email, "gender": user.gender})

    return jsonify({"error": "Invalid credentials"}), 401

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
