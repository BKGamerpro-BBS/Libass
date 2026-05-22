import os
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
from flask_login import LoginManager
from models import db, init_db, User

# Import Blueprints
from routes.auth import auth_bp
from routes.profile import profile_bp
from routes.rating import rating_bp
from routes.suggestions import suggestions_bp
from routes.wardrobe import wardrobe_bp

def create_app():
    app = Flask(__name__)
    
    # Basic Config
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'default-dev-secret-key-change-in-production')
    
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

    # Register Blueprints
    # Base URL from e2e_app_test.py is /api/libaas
    app.register_blueprint(auth_bp, url_prefix='/api/libaas/auth')
    app.register_blueprint(profile_bp, url_prefix='/api/libaas/profile')
    app.register_blueprint(wardrobe_bp, url_prefix='/api/libaas/wardrobe')
    app.register_blueprint(suggestions_bp, url_prefix='/api/libaas')
    app.register_blueprint(rating_bp, url_prefix='/api/libaas')
    
    # Serve uploaded images (wardrobe photos, rating photos)
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
            "changelog": "Bug fixes: upload/rating crashes, nav bar animation glitch, image serving"
        }), 200

    return app

app = create_app()

if __name__ == '__main__':
    # Start the server locally
    app.run(debug=True, port=5000)
