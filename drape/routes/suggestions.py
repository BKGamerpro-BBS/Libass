import uuid
import json
import urllib.request
from collections import Counter
from flask import Blueprint, jsonify, request
from flask_login import login_required, current_user
from models import db, Profile, WardrobeItem, OutfitFeedback, SavedLook
from ai_engine import generate_suggestions, get_wardrobe_insights

suggestions_bp = Blueprint('suggestions', __name__)

def get_profile_and_wardrobe():
    profile = Profile.query.filter_by(user_id=current_user.id).first()
    p_dict = {}
    if profile:
        p_dict = {
            "user_id": profile.user_id, "height_cm": profile.height_cm,
            "chest_cm": profile.chest_cm, "high_waist_cm": profile.high_waist_cm,
            "waist_cm": profile.waist_cm, "hip_cm": profile.hip_cm,
            "body_shape": profile.body_shape
        }

    items = WardrobeItem.query.filter_by(user_id=current_user.id).all()
    wardrobe = [{
        "id": i.id, "image_path": i.image_path, "name": i.name,
        "category": i.category, "specific_type": i.specific_type,
        "color": i.color, "pattern": i.pattern, "fit": i.fit,
        "occasion": i.occasion, "season": i.season or 'all'
    } for i in items]

    feedbacks = OutfitFeedback.query.filter_by(user_id=current_user.id).all()
    feedback = {f.combo_hash: f.is_liked for f in feedbacks}

    return p_dict, wardrobe, feedback

@suggestions_bp.route('/suggestions', methods=['GET'])
@login_required
def suggestions():
    weather = request.args.get('weather', 'summer').lower()
    occasion = request.args.get('occasion', 'casual').lower()
    persona = request.args.get('persona', 'casual').lower()

    profile, wardrobe, feedback = get_profile_and_wardrobe()
    suggs = generate_suggestions(profile, wardrobe, feedback, weather, occasion, persona)
    return jsonify(suggs)

@suggestions_bp.route('/weather', methods=['GET'])
def get_weather():
    """Fetch weather from Open-Meteo (completely free, no API key needed). Returns both °F and °C.
    Accepts ?lat=...&lon=... query params from the browser's Geolocation API."""
    try:
        lat = request.args.get('lat', '40.71')
        lon = request.args.get('lon', '-74.01')
        url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            current = data.get('current_weather', {})
            temp_c = current.get('temperature', 20)
            temp_f = round((temp_c * 9/5) + 32)
            weathercode = current.get('weathercode', 0)

            if weathercode in [0, 1]:
                condition = "Clear"
            elif weathercode in [2, 3]:
                condition = "Cloudy"
            elif weathercode in [51, 53, 55, 61, 63, 65, 80, 81, 82]:
                condition = "Rainy"
            elif weathercode in [71, 73, 75, 85, 86]:
                condition = "Snowy"
            else:
                condition = "Clear"

            return jsonify({
                "temperature_f": temp_f,
                "temperature_c": round(temp_c),
                "condition": condition
            })
    except Exception as e:
        print("Weather fetch error:", e)
        return jsonify({
            "temperature_f": 72,
            "temperature_c": 22,
            "condition": "Sunny (Mock)"
        })

@suggestions_bp.route('/feedback', methods=['POST'])
@login_required
def save_feedback():
    data = request.json
    item_ids = data.get('item_ids', [])
    is_liked = data.get('is_liked', 1)

    if not item_ids:
        return jsonify({"error": "No items"}), 400

    combo_hash = ",".join(sorted(item_ids))

    # Delete existing feedback for this combo, then insert new
    OutfitFeedback.query.filter_by(user_id=current_user.id, combo_hash=combo_hash).delete()
    fb = OutfitFeedback(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        combo_hash=combo_hash,
        is_liked=is_liked
    )
    db.session.add(fb)
    db.session.commit()
    return jsonify({"success": True})

@suggestions_bp.route('/insights', methods=['GET'])
@login_required
def insights():
    profile, wardrobe, _ = get_profile_and_wardrobe()
    if not profile:
        return jsonify({"missing": [], "tips": "Set up your profile first!"})
    ins = get_wardrobe_insights(profile, wardrobe)
    return jsonify(ins)

@suggestions_bp.route('/saved_looks', methods=['GET', 'POST'])
@login_required
def saved_looks():
    if request.method == 'POST':
        data = request.json
        look = SavedLook(
            id=str(uuid.uuid4()),
            user_id=current_user.id,
            outfit_data=data.get('outfit_data'),
            reasoning=data.get('reasoning', ''),
            season=data.get('season', 'all'),
            occasion=data.get('occasion', 'casual')
        )
        db.session.add(look)
        db.session.commit()
        return jsonify({"success": True, "id": look.id})

    else:
        looks = SavedLook.query.filter_by(user_id=current_user.id).all()
        return jsonify([{
            "id": l.id, "user_id": l.user_id, "outfit_data": l.outfit_data,
            "reasoning": l.reasoning, "season": l.season, "occasion": l.occasion
        } for l in looks])

@suggestions_bp.route('/color_palette', methods=['GET'])
@login_required
def color_palette():
    items = WardrobeItem.query.filter_by(user_id=current_user.id).all()
    if not items:
        return jsonify({"dominant": [], "clashing": []})

    colors = [i.color.lower() for i in items if i.color]
    counts = Counter(colors)
    dominant = counts.most_common(3)

    clashing = []
    if 'red' in counts and 'green' in counts:
        clashing.append("Red and Green items found — these can clash unless styled carefully.")
    if 'black' in counts and 'navy' in counts:
        clashing.append("Black and Navy found — ensure textures vary if worn together.")

    return jsonify({
        "dominant": [{"color": c[0], "count": c[1]} for c in dominant],
        "clashing": clashing
    })
