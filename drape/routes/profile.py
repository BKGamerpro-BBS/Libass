from flask import Blueprint, request, jsonify
from flask_login import login_required, current_user
from models import db, Profile
from ai_engine import classify_body_shape

profile_bp = Blueprint('profile', __name__)

@profile_bp.route('', methods=['GET', 'POST'])
@login_required
def profile():
    if request.method == 'POST':
        data = request.json or {}
        
        # Update user gender if provided
        if 'gender' in data and data['gender']:
            current_user.gender = data['gender']

        # Calculate body shape if measurements are provided
        shape = None
        if any(data.get(k) is not None for k in ['chest_cm', 'high_waist_cm', 'waist_cm', 'hip_cm']):
            shape = classify_body_shape(
                data.get('chest_cm'),
                data.get('high_waist_cm'),
                data.get('waist_cm'),
                data.get('hip_cm')
            )

        existing = Profile.query.filter_by(user_id=current_user.id).first()
        if existing:
            if 'name' in data:
                existing.name = data.get('name')
            if 'height_cm' in data:
                existing.height_cm = data.get('height_cm')
            if 'chest_cm' in data:
                existing.chest_cm = data.get('chest_cm')
            if 'high_waist_cm' in data:
                existing.high_waist_cm = data.get('high_waist_cm')
            if 'waist_cm' in data:
                existing.waist_cm = data.get('waist_cm')
            if 'hip_cm' in data:
                existing.hip_cm = data.get('hip_cm')
            if shape:
                existing.body_shape = shape
        else:
            existing = Profile(
                user_id=current_user.id,
                name=data.get('name'),
                height_cm=data.get('height_cm'),
                chest_cm=data.get('chest_cm'),
                high_waist_cm=data.get('high_waist_cm'),
                waist_cm=data.get('waist_cm'),
                hip_cm=data.get('hip_cm'),
                body_shape=shape or 'Unspecified'
            )
            db.session.add(existing)

        db.session.commit()
        return jsonify({
            "user_id": current_user.id,
            "email": current_user.email,
            "gender": current_user.gender,
            "name": existing.name,
            "height_cm": existing.height_cm,
            "chest_cm": existing.chest_cm,
            "high_waist_cm": existing.high_waist_cm,
            "waist_cm": existing.waist_cm,
            "hip_cm": existing.hip_cm,
            "body_shape": existing.body_shape
        })

    else:
        p = Profile.query.filter_by(user_id=current_user.id).first()
        return jsonify({
            "user_id": current_user.id,
            "email": current_user.email,
            "gender": getattr(current_user, 'gender', 'unspecified'),
            "name": p.name if p else None,
            "height_cm": p.height_cm if p else None,
            "chest_cm": p.chest_cm if p else None,
            "high_waist_cm": p.high_waist_cm if p else None,
            "waist_cm": p.waist_cm if p else None,
            "hip_cm": p.hip_cm if p else None,
            "body_shape": p.body_shape if p else None
        })

