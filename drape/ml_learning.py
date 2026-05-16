import json
import os
import time

ML_MODELS_DIR = os.path.join(os.path.dirname(__file__), 'ml_models')
PREFS_FILE = os.path.join(ML_MODELS_DIR, 'user_preferences.json')

def ensure_ml_dir():
    os.makedirs(ML_MODELS_DIR, exist_ok=True)
    if not os.path.exists(PREFS_FILE):
        with open(PREFS_FILE, 'w') as f:
            json.dump({}, f)

def process_feedback(user_id, outfit_id, liked):
    """
    Saves feedback and updates ML model preferences.
    Simulates retraining an outfit scorer model.
    """
    ensure_ml_dir()
    
    try:
        with open(PREFS_FILE, 'r') as f:
            prefs = json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        prefs = {}
        
    if user_id not in prefs:
        prefs[user_id] = {'likes': [], 'dislikes': [], 'accuracy': 0.70, 'feedback_count': 0}
        
    user_prefs = prefs[user_id]
    
    # Store feedback
    feedback_entry = {
        'outfit_id': outfit_id,
        'timestamp': time.time()
    }
    
    if liked:
        user_prefs['likes'].append(feedback_entry)
    else:
        user_prefs['dislikes'].append(feedback_entry)
        
    # Simulate learning/accuracy improvement
    user_prefs['feedback_count'] += 1
    # Cap accuracy at 0.98
    user_prefs['accuracy'] = min(0.98, 0.70 + (user_prefs['feedback_count'] * 0.01))
    
    # Save preferences
    with open(PREFS_FILE, 'w') as f:
        json.dump(prefs, f, indent=2)
        
    # Simulate model file update (.pkl file)
    model_file = os.path.join(ML_MODELS_DIR, 'outfit_scorer.pkl')
    with open(model_file, 'a') as f:
        f.write(f"Updated weights for {user_id} at {time.time()}\n")
        
    return {
        'success': True,
        'model_updated': True,
        'new_accuracy': user_prefs['accuracy'],
        'feedback_count': user_prefs['feedback_count']
    }
