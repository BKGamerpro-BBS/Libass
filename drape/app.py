import os
from flask import Flask
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
    app.register_blueprint(suggestions_bp, url_prefix='/api/libaas/suggestions')
    app.register_blueprint(rating_bp, url_prefix='/api/libaas/rating')
    
    return app

app = create_app()

if __name__ == '__main__':
    # Start the server locally
    app.run(debug=True, port=5000)
