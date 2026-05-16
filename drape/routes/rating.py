"""
LIBASS Outfit Rating Route — Camera-to-AI rating pipeline.
"""
import os
import uuid
import json
from flask import Blueprint, request, jsonify, current_app
from flask_login import login_required, current_user
from models import db, OutfitRating
from ai_engine import OrchestratorAgent

rating_bp = Blueprint('rating', __name__)


@rating_bp.route('/rate_outfit', methods=['POST'])
@login_required
def rate_outfit():
    """Accept a photo upload, run it through the AI pipeline, return a 1-10 rating."""
    if 'image' not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({"error": "No file selected"}), 400

    ext = file.filename.rsplit('.', 1)[-1].lower()
    if ext not in ['jpg', 'jpeg', 'png', 'webp']:
        return jsonify({"error": "Invalid file type"}), 400

    # Save the uploaded photo
    photo_id = str(uuid.uuid4())
    filename = f"rating_{photo_id}.{ext}"
    filepath = os.path.join(current_app.config['UPLOAD_FOLDER'], filename)
    file.save(filepath)

    # Run through the OrchestratorAgent pipeline
    score, feedback, improvements = OrchestratorAgent.rate_outfit_photo(filepath)

    # Persist the rating
    rating = OutfitRating(
        id=photo_id,
        user_id=current_user.id,
        image_path=f"/uploads/{filename}",
        score=score,
        feedback_text=feedback,
        improvements=json.dumps(improvements)
    )
    db.session.add(rating)
    db.session.commit()

    return jsonify({
        "id": photo_id,
        "image_path": f"/uploads/{filename}",
        "score": score,
        "feedback": feedback,
        "improvements": improvements
    })


@rating_bp.route('/rate_outfit/<rating_id>', methods=['GET'])
@login_required
def get_rating(rating_id):
    """Retrieve a previously saved rating."""
    rating = OutfitRating.query.filter_by(id=rating_id, user_id=current_user.id).first()
    if not rating:
        return jsonify({"error": "Rating not found"}), 404

    return jsonify({
        "id": rating.id,
        "image_path": rating.image_path,
        "score": rating.score,
        "feedback": rating.feedback_text,
        "improvements": json.loads(rating.improvements or '[]')
    })


@rating_bp.route('/ratings', methods=['GET'])
@login_required
def get_all_ratings():
    """Retrieve all ratings for the current user."""
    ratings = OutfitRating.query.filter_by(user_id=current_user.id).all()
    return jsonify([{
        "id": r.id,
        "image_path": r.image_path,
        "score": r.score,
        "feedback": r.feedback_text,
        "improvements": json.loads(r.improvements or '[]')
    } for r in ratings])
