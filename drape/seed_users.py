import sys
import os
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from app import create_app
from models import db, User
from werkzeug.security import generate_password_hash
import uuid

app = create_app()

def seed():
    with app.app_context():
        # Check if exists
        male = User.query.filter_by(email='test_male@example.com').first()
        if not male:
            male = User(id=str(uuid.uuid4()), email='test_male@example.com', password_hash=generate_password_hash('password123'), gender='male')
            db.session.add(male)
        else:
            male.password_hash = generate_password_hash('password123')
            
        female = User.query.filter_by(email='test_female@example.com').first()
        if not female:
            female = User(id=str(uuid.uuid4()), email='test_female@example.com', password_hash=generate_password_hash('password123'), gender='female')
            db.session.add(female)
        else:
            female.password_hash = generate_password_hash('password123')
            
        db.session.commit()
        print("Test users created:")
        print("1. Male: test_male@example.com / password123")
        print("2. Female: test_female@example.com / password123")

if __name__ == '__main__':
    seed()
