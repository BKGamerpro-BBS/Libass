from flask import Blueprint, request, jsonify
from flask_login import login_required, current_user
from models import db, Profile
from ai_engine import classify_body_shape

profile_bp = Blueprint('profile', __name__)

@profile_bp.route('', methods=['GET', 'POST'])
@login_required
def profile():
    if request.method == 'POST':
        data = request.json
        shape = classify_body_shape(
            data.get('chest_cm'),
            data.get('high_waist_cm'),
            data.get('waist_cm'),
            data.get('hip_cm')
        )

        if not shape:
            return jsonify({"error": "Invalid measurements"}), 400

        # Upsert profile
        existing = Profile.query.filter_by(user_id=current_user.id).first()
        if existing:
            existing.height_cm = data.get('height_cm')
            existing.chest_cm = data.get('chest_cm')
            existing.high_waist_cm = data.get('high_waist_cm')
            existing.waist_cm = data.get('waist_cm')
            existing.hip_cm = data.get('hip_cm')
            existing.body_shape = shape
        else:
            p = Profile(
                user_id=current_user.id,
                height_cm=data.get('height_cm'),
                chest_cm=data.get('chest_cm'),
                high_waist_cm=data.get('high_waist_cm'),
                waist_cm=data.get('waist_cm'),
                hip_cm=data.get('hip_cm'),
                body_shape=shape
            )
            db.session.add(p)

        db.session.commit()
        p = Profile.query.filter_by(user_id=current_user.id).first()
        return jsonify({
            "user_id": p.user_id, "height_cm": p.height_cm,
            "chest_cm": p.chest_cm, "high_waist_cm": p.high_waist_cm,
            "waist_cm": p.waist_cm, "hip_cm": p.hip_cm,
            "body_shape": p.body_shape
        })

    else:
        p = Profile.query.filter_by(user_id=current_user.id).first()
        if p:
            return jsonify({
                "user_id": p.user_id, "height_cm": p.height_cm,
                "chest_cm": p.chest_cm, "high_waist_cm": p.high_waist_cm,
                "waist_cm": p.waist_cm, "hip_cm": p.hip_cm,
                "body_shape": p.body_shape
            })
        return jsonify({})
