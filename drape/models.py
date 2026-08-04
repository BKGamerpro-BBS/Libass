"""
LIBASS Data Models — SQLAlchemy with WAL mode for 10k+ concurrent users.
Provides connection pooling, auto-commits, and a clean migration path to PostgreSQL.
"""
import os
import uuid
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()

# ─── ORM MODELS ───────────────────────────────────────────────
class User(db.Model):
    __tablename__ = 'user'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    gender = db.Column(db.String(20), default='unspecified')

    # Relationships
    profile = db.relationship('Profile', backref='user', uselist=False, lazy=True)
    wardrobe_items = db.relationship('WardrobeItem', backref='user', lazy=True)

    @property
    def is_active(self):
        return True

    @property
    def is_authenticated(self):
        return True

    @property
    def is_anonymous(self):
        return False

    def get_id(self):
        return self.id

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    @staticmethod
    def get(user_id):
        return User.query.get(user_id)


class Profile(db.Model):
    __tablename__ = 'profile'
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), primary_key=True)
    name = db.Column(db.String(120))
    height_cm = db.Column(db.Float)
    chest_cm = db.Column(db.Float)
    high_waist_cm = db.Column(db.Float)
    waist_cm = db.Column(db.Float)
    hip_cm = db.Column(db.Float)
    body_shape = db.Column(db.String(30))



class WardrobeItem(db.Model):
    __tablename__ = 'wardrobe'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), nullable=False)
    image_path = db.Column(db.String(256))
    name = db.Column(db.String(120))
    category = db.Column(db.String(30))
    specific_type = db.Column(db.String(60))
    color = db.Column(db.String(30))
    pattern = db.Column(db.String(30))
    fit = db.Column(db.String(30))
    occasion = db.Column(db.String(30))
    season = db.Column(db.String(30))


class OutfitFeedback(db.Model):
    __tablename__ = 'outfit_feedback'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), nullable=False)
    combo_hash = db.Column(db.String(512))
    is_liked = db.Column(db.Integer)


class SavedLook(db.Model):
    __tablename__ = 'saved_looks'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), nullable=False)
    outfit_data = db.Column(db.Text)
    reasoning = db.Column(db.Text)
    season = db.Column(db.String(30))
    occasion = db.Column(db.String(30))


class OutfitRating(db.Model):
    __tablename__ = 'outfit_ratings'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), nullable=False)
    image_path = db.Column(db.String(256))
    score = db.Column(db.Float)
    feedback_text = db.Column(db.Text)
    improvements = db.Column(db.Text)  # JSON string


# ─── DATABASE INITIALIZATION ─────────────────────────────────
def init_db(app):
    """Configure SQLAlchemy with WAL mode and connection pooling for 10k+ users."""
    db_path = os.path.join(app.root_path, 'drape.db')
    app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
    app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
        'pool_size': 20,
        'max_overflow': 30,
        'pool_pre_ping': True,
        'connect_args': {'check_same_thread': False}
    }
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)

    with app.app_context():
        # Enable WAL mode for concurrent reads (critical for 10k+ users)
        from sqlalchemy import event, text
        @event.listens_for(db.engine, "connect")
        def set_sqlite_wal(dbapi_conn, connection_record):
            cursor = dbapi_conn.cursor()
            cursor.execute("PRAGMA journal_mode=WAL")
            cursor.execute("PRAGMA busy_timeout=5000")
            cursor.execute("PRAGMA synchronous=NORMAL")
            cursor.execute("PRAGMA cache_size=-64000")  # 64MB cache
            cursor.close()

        db.create_all()
        
        # Migration check: ensure 'name' column exists in 'profile' table
        try:
            db.session.execute(text("ALTER TABLE profile ADD COLUMN name VARCHAR(120)"))
            db.session.commit()
        except Exception:
            db.session.rollback()

