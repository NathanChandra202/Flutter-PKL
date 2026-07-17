import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

import cv2
import numpy as np
import pytesseract
from deepface import DeepFace
import re

def _extract_face_array(image_path: str) -> tuple[np.ndarray | None, str | None]:
    try:
        faces = DeepFace.extract_faces(
            img_path=image_path,
            detector_backend='retinaface',
            enforce_detection=True,
            align=True,
            normalize_face=True,
        )

        if not faces:
            return None, "No face detected"

        first_face = faces[0]
        if isinstance(first_face, list):
            first_face = first_face[0] if first_face else None

        if isinstance(first_face, dict) and first_face.get('face') is not None:
            return np.asarray(first_face['face']), None

        return None, "No face data returned"
    except Exception as e:
        return None, str(e)

def verify_face_match(img1_path: str, img2_path: str) -> dict:
    """
    Verifies if two faces belong to the same person.
    """
    face1, err1 = _extract_face_array(img1_path)
    face2, err2 = _extract_face_array(img2_path)

    if err1:
        return {"error": f"KTP face extraction failed: {err1}", "verified": False}
    if err2:
        return {"error": f"Selfie face extraction failed: {err2}", "verified": False}

    try:
        result = DeepFace.verify(
            img1_path=face1,
            img2_path=face2,
            model_name="Facenet",
            enforce_detection=False,
        )
        distance = result.get("distance")
        return {
            "verified": result.get("verified", False),
            "distance": distance,
            "similarity": 1 - distance if distance is not None else None,
        }
    except Exception as e:
        return {"error": str(e), "verified": False}

def extract_ktp_data(ktp_path: str) -> dict:
    """
    Extracts NIK and Name from KTP using OCR.
    """
    try:
        # Ensure Tesseract is installed on the system (Windows requires path setup usually)
        # pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
        
        img = cv2.imread(ktp_path)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Simple preprocessing
        gray = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)[1]
        
        text = pytesseract.image_to_string(gray)
        
        # Basic regex to find NIK (16 digits)
        nik_match = re.search(r'\b\d{16}\b', text)
        nik = nik_match.group(0) if nik_match else None
        
        return {
            "raw_text": text,
            "nik": nik
        }
    except Exception as e:
        return {"error": str(e)}

