import os
import logging
from flask import Flask, jsonify, send_from_directory, request
from flask_cors import CORS
from flask_login import LoginManager
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from dotenv import load_dotenv
from models import db, init_db, User

from extensions import limiter

# Load environment variables from .env
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')


# Import Blueprints
from routes.auth import auth_bp
from routes.profile import profile_bp
from routes.rating import rating_bp
from routes.suggestions import suggestions_bp
from routes.wardrobe import wardrobe_bp

def create_app():
    app = Flask(__name__)
    
    # Security Config
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-fallback-secret-key-change-in-production')
    app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024  # Enforce 10MB maximum payload/upload limit
    
    # Initialize Rate Limiter
    limiter.init_app(app)
    
    # Upload folder — used by wardrobe and rating routes to save images
    upload_dir = os.path.join(app.root_path, 'uploads')
    os.makedirs(upload_dir, exist_ok=True)
    app.config['UPLOAD_FOLDER'] = upload_dir
    
    # Enable CORS
    CORS(app, supports_credentials=True)
    
    # Initialize Database and WAL mode settings
    init_db(app)
    
    # Initialize Flask-Login
    login_manager = LoginManager()
    login_manager.init_app(app)
    
    @login_manager.user_loader
    def load_user(user_id):
        return User.query.get(user_id)

    # Security Headers Middleware
    @app.after_request
    def add_security_headers(response):
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'DENY'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        return response

    # Global Error Handlers — Prevents stack traces, raw SQL, or path leakage
    @app.errorhandler(429)
    def ratelimit_handler(e):
        return jsonify({
            "error": "Too many requests. Please slow down and try again later.",
            "retry_after": getattr(e, 'description', 60)
        }), 429

    @app.errorhandler(400)
    def bad_request_handler(e):
        desc = getattr(e, 'description', 'Bad request.')
        return jsonify({"error": str(desc)}), 400

    @app.errorhandler(413)
    def request_entity_too_large(e):
        return jsonify({"error": "File size exceeds maximum allowed limit (10MB)."}), 413

    @app.errorhandler(Exception)
    def handle_unexpected_error(e):
        logging.exception(f"Unhandled server exception: {e}")
        return jsonify({"error": "An internal server error occurred."}), 500

    # Register Blueprints
    app.register_blueprint(auth_bp, url_prefix='/api/libaas/auth')
    app.register_blueprint(profile_bp, url_prefix='/api/libaas/profile')
    app.register_blueprint(wardrobe_bp, url_prefix='/api/libaas/wardrobe')
    app.register_blueprint(suggestions_bp, url_prefix='/api/libaas')
    app.register_blueprint(rating_bp, url_prefix='/api/libaas')
    
    # Serve uploaded images securely
    @app.route('/uploads/<path:filename>')
    def serve_upload(filename):
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

    # Health check / root route
    @app.route('/')
    def health_check():
        return jsonify({"status": "ok", "service": "LIBASS Backend API", "version": "2.0.1"}), 200

    # App version check endpoint — Flutter app polls this to detect updates
    @app.route('/api/libaas/version')
    def app_version():
        return jsonify({
            "latest_version": "2.0.1",
            "min_version": "2.0.0",
            "download_url": "https://github.com/BKGamerpro-BBS/Libass/releases/latest",
            "changelog": "Security hardening: Rate limiting, input validation, file upload magic-byte verification"
        }), 200

    return app

app = create_app()

if __name__ == '__main__':
    # Start the server listening on all network interfaces (accessible via LAN/Wi-Fi IP)
    app.run(host='0.0.0.0', debug=True, port=5000)

