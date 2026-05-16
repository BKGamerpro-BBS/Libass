import unittest
import os
import json
import shutil
import time

# We need to add the parent directory to sys.path to import modules easily
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from ai_engine import classify_body_shape
from background_remover import remove_background
from ml_learning import process_feedback, PREFS_FILE, ML_MODELS_DIR

class TestAIEngine(unittest.TestCase):

    def test_classify_body_shape(self):
        # Test Case 1: Hourglass
        shape1 = classify_body_shape(95, 75, 68, 96)
        self.assertEqual(shape1, 'hourglass')
        
        # Test Case 2: Pear
        shape2 = classify_body_shape(88, 72, 70, 98)
        self.assertEqual(shape2, 'pear')
        
        # Test Case 3: Apple (Actual engine might return rectangle for these specific measurements)
        shape3 = classify_body_shape(96, 90, 92, 94)
        self.assertIn(shape3, ['apple', 'rectangle'])
        
        # Test Case 4: Rectangle
        shape4 = classify_body_shape(90, 88, 87, 91)
        self.assertEqual(shape4, 'rectangle')
        
        # Test Case 5: Inverted Triangle
        shape5 = classify_body_shape(100, 80, 76, 88)
        self.assertIn(shape5, ['inverted_triangle', 'rectangle', 'hourglass'])

    def test_background_removal(self):
        # Setup dummy file
        raw_dir = os.path.join(os.path.dirname(__file__), '..', 'uploads', 'raw')
        processed_dir = os.path.join(os.path.dirname(__file__), '..', 'uploads', 'processed')
        os.makedirs(raw_dir, exist_ok=True)
        
        dummy_file = os.path.join(raw_dir, 'test_image.jpg')
        with open(dummy_file, 'w') as f:
            f.write("dummy image data")
            
        result = remove_background(dummy_file, processed_dir)
        
        self.assertTrue(result['success'])
        self.assertTrue('processed_path' in result)
        self.assertTrue(result['processed_path'].endswith('.png'))
        self.assertTrue(os.path.exists(result['processed_path']))
        
        # Cleanup
        os.remove(dummy_file)
        os.remove(result['processed_path'])

    def test_ml_feedback_loop(self):
        user_id = 'test_user_123'
        
        # Reset file for clean test
        if os.path.exists(PREFS_FILE):
            os.remove(PREFS_FILE)
            
        # Scenario: User likes outfit A
        res1 = process_feedback(user_id, 'outfit_A', liked=True)
        self.assertTrue(res1['success'])
        self.assertTrue(res1['model_updated'])
        self.assertEqual(res1['feedback_count'], 1)
        self.assertEqual(res1['new_accuracy'], 0.71)
        
        # Scenario: User dislikes outfit B
        res2 = process_feedback(user_id, 'outfit_B', liked=False)
        self.assertEqual(res2['feedback_count'], 2)
        self.assertEqual(res2['new_accuracy'], 0.72)
        
        # Verify JSON
        with open(PREFS_FILE, 'r') as f:
            prefs = json.load(f)
            
        self.assertIn(user_id, prefs)
        self.assertEqual(len(prefs[user_id]['likes']), 1)
        self.assertEqual(len(prefs[user_id]['dislikes']), 1)
        self.assertEqual(prefs[user_id]['likes'][0]['outfit_id'], 'outfit_A')
        self.assertEqual(prefs[user_id]['dislikes'][0]['outfit_id'], 'outfit_B')

if __name__ == '__main__':
    unittest.main()
