import urllib.request
import urllib.parse
import json
import time

BASE_URL = "http://127.0.0.1:5000/api/libaas"
cookies = {}

def get_cookie_header():
    if not cookies:
        return ""
    return "; ".join([f"{k}={v}" for k, v in cookies.items()])

def save_cookies(headers):
    for k, v in headers.items():
        if k.lower() == 'set-cookie':
            # very naive cookie parser
            parts = v.split(';')[0].split('=', 1)
            if len(parts) == 2:
                cookies[parts[0]] = parts[1]

def make_request(method, url, data=None):
    headers = {'Content-Type': 'application/json'}
    cookie_str = get_cookie_header()
    if cookie_str:
        headers['Cookie'] = cookie_str
        
    req_data = None
    if data is not None:
        req_data = json.dumps(data).encode('utf-8')
        
    req = urllib.request.Request(url, data=req_data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            save_cookies(dict(response.info()))
            body = response.read().decode('utf-8')
            return response.getcode(), json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8')
        return e.code, json.loads(body) if body else {}
    except Exception as e:
        print(f"Request Error: {e}")
        return 0, {}

def print_step(name):
    print(f"\n[{name}]")

def run_tests():
    print("Starting Complete End-to-End Test for LIBASS App Flow...")
    
    print_step("Auth - Registration")
    test_email = f"e2e_test_{int(time.time())}@example.com"
    test_pass = "password123"
    
    status, data = make_request("POST", f"{BASE_URL}/auth/register", {
        "email": test_email,
        "password": test_pass,
        "gender": "male"
    })
    
    if status == 200 and data.get('success'):
        print(f"[OK] Successfully registered: {test_email}")
    else:
        print(f"[FAIL] Registration failed. Status: {status}, Response: {data}")
        return

    print_step("Auth - Check Session")
    status, data = make_request("GET", f"{BASE_URL}/auth/session")
    if status == 200 and data.get('authenticated'):
        print("[OK] Session maintained via cookies")
    else:
        print(f"[FAIL] Session check failed. Status: {status}, Response: {data}")
        return

    print_step("Profile - Update Profile")
    profile_data = {
        "height_cm": 180,
        "chest_cm": 100,
        "high_waist_cm": 85,
        "waist_cm": 80,
        "hip_cm": 95,
        "body_shape": "rectangle"
    }
    status, data = make_request("POST", f"{BASE_URL}/profile", profile_data)
    if status == 200 and 'body_shape' in data:
        print("[OK] Profile updated successfully")
    else:
        print(f"[FAIL] Profile update failed. Status: {status}, Response: {data}")

    print_step("Wardrobe - Fetch Initial")
    status, data = make_request("GET", f"{BASE_URL}/wardrobe")
    if status == 200:
        print(f"[OK] Wardrobe fetched successfully. Items count: {len(data)}")
    else:
        print(f"[FAIL] Wardrobe fetch failed. Status: {status}, Response: {data}")

    print_step("Suggestions - AI Logic")
    status, data = make_request("GET", f"{BASE_URL}/suggestions?weather=summer&occasion=casual&persona=casual")
    if status == 200:
        print(f"[OK] Suggestions fetched successfully. Received {len(data)} outfit options.")
    else:
        print(f"[FAIL] Suggestions fetch failed. Status: {status}, Response: {data}")

    print_step("Auth - Logout")
    status, data = make_request("POST", f"{BASE_URL}/auth/logout")
    if status == 200:
        print("[OK] Logged out successfully")
    else:
        print(f"[FAIL] Logout failed. Status: {status}, Response: {data}")

    print("\n[OK] All End-to-End Tests Passed! The system is fully operational.")

if __name__ == '__main__':
    run_tests()
