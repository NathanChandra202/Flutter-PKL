import cv2
import pytesseract
from deepface import DeepFace
import os
import re

def verify_face_match(img1_path: str, img2_path: str) -> dict:
    """
    Verifies if two faces belong to the same person.
    """
    try:
        # Uses VGG-Face or Facenet by default. We use Facenet as it's quite fast and accurate
        result = DeepFace.verify(img1_path=img1_path, img2_path=img2_path, model_name="Facenet")
        return {
            "verified": result["verified"],
            "distance": result["distance"],
            "similarity": 1 - result["distance"] # rough approximation
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

def check_liveness_simple(image_path: str) -> bool:
    """
    A very simple static image liveness check.
    In a real app, you'd use a sequence of frames for blink/smile detection, 
    or an AI model trained for anti-spoofing.
    Here we just check if a face can be clearly detected and has eyes using OpenCV Haarcascades.
    """
    try:
        face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        eye_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_eye.xml')
        
        img = cv2.imread(image_path)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        faces = face_cascade.detectMultiScale(gray, 1.3, 5)
        
        if len(faces) == 0:
            return False # No face detected
            
        for (x, y, w, h) in faces:
            roi_gray = gray[y:y+h, x:x+w]
            eyes = eye_cascade.detectMultiScale(roi_gray)
            if len(eyes) >= 1:
                return True # Found face with at least an eye (very basic)
                
        return False
    except Exception as e:
        print(f"Liveness check error: {e}")
        return False
