# DRAPE - AI-Powered Personal Stylist

DRAPE is a full-stack, local web application that acts as your personal wardrobe stylist. It uses your body measurements to determine your body shape and provides intelligent outfit suggestions from your uploaded wardrobe.

## Features
- **Body Shape Detection**: Input your measurements and discover your shape (Hourglass, Pear, Apple, Rectangle, Inverted Triangle).
- **Wardrobe Management**: Upload images of your clothing, tag them with metadata (category, fit, occasion, etc.).
- **Outfit Suggestions**: Get daily mix-and-match outfit suggestions tailored to your body shape and occasion.
- **Wardrobe Insights**: Find out what pieces are missing from your wardrobe to complete your style.

## Technologies Used
- Backend: Python, Flask, SQLite
- Frontend: HTML5, CSS3, Vanilla JavaScript
- UI/UX: Custom Design System

## Setup Instructions
1. Ensure you have Python 3.8+ installed.
2. Clone or download this repository.
3. Open a terminal and navigate to the `drape` directory.
4. (Optional) Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
5. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## How to Run
Start the application by running:
```bash
python app.py
```
The server will start at `http://localhost:5000`.

## How to Use
1. Open your browser and go to `http://localhost:5000`.
2. Click **Get Started** and enter your measurements to reveal your body shape.
3. Navigate to **Wardrobe** and upload photos of your clothing items (at least 3 items recommended).
4. Go to **Outfits** to see AI-generated outfit suggestions.
5. Check **Insights** to see recommendations for completing your wardrobe.
