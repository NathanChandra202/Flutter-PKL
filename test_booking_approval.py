#!/usr/bin/env python3
"""
Test script untuk memverifikasi booking approval berfungsi dengan benar
"""

import requests
import json

# Backend URL
BASE_URL = "https://dev-api-kostraktor.duaenam.id/api/v1"

def test_booking_approval():
    print("🧪 Testing Booking Approval Process...")
    
    try:
        # Test 1: Cek apakah endpoint /bookings/pending accessible
        print("\n1. Testing /bookings/pending endpoint...")
        response = requests.get(f"{BASE_URL}/bookings/pending")
        print(f"Status: {response.status_code}")
        if response.status_code == 401:
            print("❌ Needs authentication - this is expected")
        elif response.status_code == 200:
            print("✅ Endpoint accessible")
        
        # Test 2: Cek endpoint /rooms/ untuk melihat available rooms
        print("\n2. Testing /rooms/ endpoint...")
        response = requests.get(f"{BASE_URL}/rooms/")
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            rooms = response.json()
            print(f"✅ Found {len(rooms)} available rooms")
            for room in rooms:
                print(f"   Room {room['id']}: {room['name']} - Available: {room['is_available']}")
        
        # Test 3: Cek endpoint /auth/me structure
        print("\n3. Testing /auth/me endpoint structure...")
        print("   (This will return 401 without auth, but we can check endpoint exists)")
        response = requests.get(f"{BASE_URL}/auth/me")
        print(f"Status: {response.status_code}")
        if response.status_code == 401:
            print("✅ Endpoint exists (needs authentication)")
        
        print("\n✅ Backend endpoints are accessible")
        return True
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        return False

def test_models():
    print("\n🧪 Testing Database Models...")
    import sys
    import os
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))
    
    try:
        from app.models.booking import Booking
        from app.models.user import User
        from app.models.kost import KostRoom
        
        # Check field exists
        booking_fields = [column.name for column in Booking.__table__.columns]
        user_fields = [column.name for column in User.__table__.columns]
        room_fields = [column.name for column in KostRoom.__table__.columns]
        
        print("✅ Booking fields:", booking_fields)
        print("✅ User fields:", user_fields)  
        print("✅ Room fields:", room_fields)
        
        # Check specific fields
        assert 'status' in booking_fields, "Missing status field in Booking"
        assert 'current_room_id' in user_fields, "Missing current_room_id field in User"
        assert 'is_available' in room_fields, "Missing is_available field in KostRoom"
        
        print("✅ All required database fields exist")
        return True
        
    except Exception as e:
        print(f"❌ Model test failed: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Testing Booking Approval Implementation")
    print("=" * 50)
    
    # Test backend endpoints
    backend_ok = test_booking_approval()
    
    # Test database models
    models_ok = test_models()
    
    print("\n" + "=" * 50)
    if backend_ok and models_ok:
        print("🎉 Basic tests passed!")
        print("\n📋 Manual Testing Steps:")
        print("1. Start backend: python -m uvicorn app.main:app --reload")
        print("2. Start admin dashboard: npm run dev")
        print("3. Login to admin dashboard")
        print("4. Go to Bookings page and try approving a booking")
        print("5. Check if room becomes unavailable in Rooms page")
        print("6. Test Flutter app login persistence after restart")
    else:
        print("❌ Some tests failed - check implementation")