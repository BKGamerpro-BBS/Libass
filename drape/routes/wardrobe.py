import os
import uuid
from flask import Blueprint, request, jsonify, current_app
from flask_login import login_required, current_user
from models import db, WardrobeItem
from ai_engine import auto_tag_image
from upload_security import validate_and_save_upload
from validators import validate_text

wardrobe_bp = Blueprint('wardrobe', __name__)

@wardrobe_bp.route('', methods=['GET', 'POST'])
@login_required
def wardrobe():
    if request.method == 'POST':
        if 'images' not in request.files and 'image' not in request.files:
            return jsonify({"error": "No images uploaded"}), 400

        files = request.files.getlist('images') or request.files.getlist('image')
        if not files or files[0].filename == '':
            return jsonify({"error": "No file selected"}), 400

        uploaded_items = []
        upload_folder = current_app.config['UPLOAD_FOLDER']

        for file in files:
            # Use upload_security magic-byte inspection, file size check & UUID generation
            ok, result_path_or_err, web_path = validate_and_save_upload(
                file, 
                upload_folder, 
                filename_prefix="wardrobe"
            )
            if not ok:
                return jsonify({"error": result_path_or_err}), 400

            filepath = result_path_or_err
            ai_tags = auto_tag_image(filepath)

            final_filepath = ai_tags.get('new_filepath', filepath)
            final_filename = os.path.basename(final_filepath)
            image_path = f"/uploads/{final_filename}"

            item = WardrobeItem(
                id=str(uuid.uuid4()),
                user_id=current_user.id,
                image_path=image_path,
                name=validate_text(request.form.get('name') or ai_tags.get('name', 'Unknown'), "name"),
                category=validate_text(request.form.get('category') or ai_tags.get('category', 'top'), "category"),
                specific_type=validate_text(request.form.get('specific_type') or ai_tags.get('specific_type', 'unknown'), "specific_type"),
                color=validate_text(request.form.get('color') or ai_tags.get('color', 'unknown'), "color"),
                pattern=validate_text(request.form.get('pattern') or ai_tags.get('pattern', 'solid'), "pattern"),
                fit=validate_text(request.form.get('fit') or 'regular', "fit"),
                occasion=validate_text(request.form.get('occasion') or 'casual', "occasion"),
                season=validate_text(request.form.get('season') or ai_tags.get('season', 'all'), "season")
            )
            db.session.add(item)
            db.session.commit()

            uploaded_items.append({
                "id": item.id, "user_id": item.user_id, "image_path": item.image_path,
                "name": item.name, "category": item.category, "specific_type": item.specific_type,
                "color": item.color, "pattern": item.pattern, "fit": item.fit,
                "occasion": item.occasion, "season": item.season or 'all'
            })

        return jsonify(uploaded_items if len(uploaded_items) > 1 else (uploaded_items[0] if uploaded_items else {}))

    else:
        items = WardrobeItem.query.filter_by(user_id=current_user.id).all()
        return jsonify([{
            "id": i.id, "user_id": i.user_id, "image_path": i.image_path,
            "name": i.name, "category": i.category, "specific_type": i.specific_type,
            "color": i.color, "pattern": i.pattern, "fit": i.fit,
            "occasion": i.occasion, "season": i.season or 'all'
        } for i in items])

@wardrobe_bp.route('/<id>', methods=['PUT'])
@login_required
def update_wardrobe_item(id):
    item = WardrobeItem.query.filter_by(id=id, user_id=current_user.id).first()
    if not item:
        return jsonify({"error": "Not found"}), 404

    data = request.json
    item.name = data.get('name', item.name)
    item.fit = data.get('fit', item.fit)
    item.specific_type = data.get('specific_type', item.specific_type)
    item.category = data.get('category', item.category)
    item.season = data.get('season', item.season)
    db.session.commit()

    return jsonify({
        "id": item.id, "user_id": item.user_id, "image_path": item.image_path,
        "name": item.name, "category": item.category, "specific_type": item.specific_type,
        "color": item.color, "pattern": item.pattern, "fit": item.fit,
        "occasion": item.occasion, "season": item.season or 'all'
    })

@wardrobe_bp.route('/<id>', methods=['DELETE'])
@login_required
def delete_wardrobe(id):
    item = WardrobeItem.query.filter_by(id=id, user_id=current_user.id).first()
    if not item:
        return jsonify({"error": "Not found"}), 404

    filename = item.image_path.split('/')[-1]
    filepath = os.path.join(current_app.config['UPLOAD_FOLDER'], filename)
    if os.path.exists(filepath):
        os.remove(filepath)

    db.session.delete(item)
    db.session.commit()
    return jsonify({"success": True})
