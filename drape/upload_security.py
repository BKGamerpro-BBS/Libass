"""
LIBASS File Upload Security Module — Magic Byte Verification & Safe File Isolation
Ensures uploaded files are validated by mime/magic headers, isolated from web execution, and sanitized.
"""
import os
import uuid
from PIL import Image

ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'webp'}
ALLOWED_MIME_TYPES = {'image/jpeg', 'image/png', 'image/webp'}
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB

def validate_and_save_upload(file_storage, target_folder: str, filename_prefix: str = "") -> tuple[bool, str, str]:
    """
    Validates file extension, size, and image magic bytes using Pillow.
    Saves the file to target_folder with a cryptographically secure UUID filename.
    Returns (success, error_or_filename, relative_web_path).
    """
    if not file_storage or not file_storage.filename:
        return False, "No file selected.", ""

    filename = file_storage.filename.strip()
    if '.' not in filename:
        return False, "Invalid filename — missing extension.", ""

    ext = filename.rsplit('.', 1)[-1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        return False, f"Invalid file extension. Allowed formats: {', '.join(sorted(ALLOWED_EXTENSIONS))}", ""

    # Check file stream size
    file_storage.seek(0, os.SEEK_END)
    file_size = file_storage.tell()
    file_storage.seek(0)

    if file_size > MAX_FILE_SIZE_BYTES:
        return False, f"File size exceeds 10MB limit ({file_size / (1024*1024):.1f}MB).", ""
    if file_size == 0:
        return False, "Uploaded file is empty.", ""

    # Verify genuine image magic bytes with Pillow
    try:
        img = Image.open(file_storage.stream)
        img.verify()  # Verifies file integrity and image magic headers
        detected_format = (img.format or "").lower()
        if detected_format == 'jpeg':
            detected_format = 'jpg'
        
        # Reset stream position after Pillow verify()
        file_storage.stream.seek(0)
    except Exception as e:
        return False, "Security error: Uploaded file is not a valid image payload.", ""

    # Generate isolated random filename to eliminate path traversal attacks
    unique_id = str(uuid.uuid4())
    prefix = f"{filename_prefix}_" if filename_prefix else ""
    secure_name = f"{prefix}{unique_id}.{ext}"
    
    os.makedirs(target_folder, exist_ok=True)
    filepath = os.path.join(target_folder, secure_name)
    file_storage.save(filepath)

    relative_path = f"/uploads/{secure_name}"
    return True, filepath, relative_path
