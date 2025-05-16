import os
import re
from flask import Flask, request, jsonify, render_template, redirect, url_for, flash
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from werkzeug.security import generate_password_hash, check_password_hash
import firebase_admin
from firebase_admin import credentials, firestore
import google.generativeai as genai
import traceback  # 放在檔案最上方
from datetime import datetime
import json
from firebase_admin import credentials, initialize_app
# ✅ 初始化 Firebase

firebase_json = os.environ.get("FIREBASE_CREDENTIALS_JSON")
if not firebase_json:
    raise ValueError("未設定 FIREBASE_CREDENTIALS_JSON 環境變數")

cred_dict = json.loads(firebase_json)
cred = credentials.Certificate(cred_dict)
initialize_app(cred)
db = firestore.client()

# ✅ 初始化 Flask
app = Flask(__name__)
app.secret_key = os.urandom(24)

# ✅ 設定 Flask-Login
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'index'

# ✅ 設定 Gemini
genai.configure(api_key="AIzaSyDuYrGNbIys4kbzDNalluGp9uyfiSamdJg")
model = genai.GenerativeModel("gemini-1.5-flash")

# ✅ 使用者類別
class User(UserMixin):
    def __init__(self, id_, username, password_hash, role):
        self.id = id_
        self.username = username
        self.password_hash = password_hash
        self.role = role

@login_manager.user_loader
def load_user(user_id):
    user_doc = db.collection("users").document(user_id).get()
    if user_doc.exists:
        data = user_doc.to_dict()
        return User(user_id, data['username'], data['password'], data['role'])
    return None

# ✅ 註冊
@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = generate_password_hash(request.form['password'])
        role = request.form['role']
        existing_users = db.collection("users").where("username", "==", username).get()
        if existing_users:
            flash("使用者名稱已存在", "danger")
            return render_template('register.html')
        db.collection("users").document().set({
            "username": username,
            "password": password,
            "role": role,
            "tokens": 0
        })
        flash("註冊成功，請登入", "success")
        return redirect(url_for('index'))
    return render_template('register.html')

# ✅ 登入
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password_input = request.form['password']
        users = db.collection("users").where("username", "==", username).get()
        if users:
            user_doc = users[0]
            user_data = user_doc.to_dict()
            if check_password_hash(user_data['password'], password_input):
                user = User(user_doc.id, user_data['username'], user_data['password'], user_data['role'])
                login_user(user)

                # 根據使用者身份轉導不同頁面
                if user.role == "organizer":
                    return redirect(url_for('organizer_dashboard'))
                else:
                    return redirect(url_for('user_dashboard'))
        flash("登入失敗，請檢查帳號密碼", "danger")
    return render_template('index.html')

# ✅ 使用者主頁（海廢辨識 + 圖鑑）
@app.route('/user/dashboard')
@login_required
def user_dashboard():
    return render_template('dashboard.html', username=current_user.username, user_id=current_user.id)

#使用者已參加之活動
@app.route('/get_joined_events')
@login_required
def get_joined_events():
    try:
        joined_events = []
        events_ref = db.collection('events').stream()
        for event in events_ref:
            participants_ref = db.collection('events').document(event.id).collection('participants')
            if participants_ref.document(current_user.id).get().exists:
                data = event.to_dict()
                data['id'] = event.id
                joined_events.append(data)
        return jsonify({'events': joined_events})
    except Exception as e:
        print(e)
        return jsonify({'events': []})


# 使用者端顯示可參加活動
@app.route('/available_events')
@login_required
def available_events():
    if current_user.role != 'user':
        flash("只有使用者可以參加活動", "danger")
        return redirect(url_for('organizer_dashboard'))

    try:
        # 取得所有活動
        events_ref = db.collection('events')
        events = events_ref.stream()
        
        # 轉成 list 傳到模板
        event_list = []
        for event in events:
            data = event.to_dict()
            data['id'] = event.id  # 加入 Firestore 的 document ID
            event_list.append(data)
        
        return render_template('available_events.html', events=event_list)
    except Exception as e:
        traceback.print_exc()
        flash("載入活動失敗", "danger")
        return redirect(url_for('user_dashboard'))

@app.route('/get_events')
@login_required
def get_events():
    try:
        events_ref = db.collection('events').stream()
        result = []
        for event in events_ref:
            data = event.to_dict()
            data['id'] = event.id
            result.append(data)
        return jsonify({'events': result})
    except Exception as e:
        print(e)
        return jsonify({'events': []})


@app.route('/join_event/<event_id>', methods=['POST'])
@login_required
def join_event(event_id):
    if current_user.role != 'user':
        flash("只有使用者可以參加活動", "danger")
        return redirect(url_for('organizer_dashboard'))

    try:
        event_doc = db.collection('events').document(event_id)
        participants_ref = event_doc.collection('participants').document(current_user.id)

        if not participants_ref.get().exists:
            participants_ref.set({
                'user_id': current_user.id,
                'joined_at': firestore.SERVER_TIMESTAMP
            })

            user_ref = db.collection("users").document(current_user.id)
            doc = user_ref.get()
            if doc.exists:
                current_tokens = doc.to_dict().get("tokens", 0)
                user_ref.set({"tokens": current_tokens + 1}, merge=True)

            flash("成功參加活動並獲得 1 代幣！", "success")
        else:
            flash("您已參加過此活動", "info")

    except Exception as e:
        traceback.print_exc()
        flash("參加活動失敗", "danger")

    return redirect(url_for('available_events'))



@app.route('/organizer/dashboard')
@login_required
def organizer_dashboard():
    if current_user.role != "organizer":
        flash("您沒有權限存取此頁面", "danger")
        return redirect(url_for('user_dashboard'))

    events = db.collection("events").where("organizer_id", "==", current_user.id).stream()
    event_list = []

    for e in events:
        event_data = e.to_dict()
        event_data['id'] = e.id
        participants = db.collection('events').document(e.id).collection('participants').stream()
        participant_list = []
        for p in participants:
            user_doc = db.collection('users').document(p.id).get()
            if user_doc.exists:
                user_data = user_doc.to_dict()
                participant_list.append(user_data.get('username', '未知使用者'))
        event_data['participants'] = participant_list
        event_list.append(event_data)

    return render_template("organizer_dashboard.html", username=current_user.username, events=event_list)



# 主辦方活動路由
@app.route('/create_event', methods=['POST'])
@login_required
def create_event():
    if current_user.role != 'organizer':
        flash("您沒有權限建立活動", "danger")
        return redirect(url_for('user_dashboard'))

    title = request.form.get('title')
    description = request.form.get('description')
    location = request.form.get('location')
    datetime_str = request.form.get('datetime')
    menu_str = request.form.get('menu')

    try:
        db.collection('events').add({
            'organizer_id': current_user.id,
            'title': title,
            'description': description,
            'location': location,
            'datetime': datetime.fromisoformat(datetime_str),
            'menu': [item.strip() for item in menu_str.split(',')]
        })
        flash("OK", "success")
    except Exception as e:
        traceback.print_exc()
        flash("fail", "danger")

    return redirect(url_for('organizer_dashboard'))

"""
{
  "organizer_id": "使用者ID",
  "title": "淨灘活動",
  "description": "歡迎一起來淨灘！",
  "location": "台中高美濕地",
  "datetime": "2025-06-15T10:00:00",
  "menu": ["環保講座", "淨灘行動", "垃圾分類挑戰"]
}

"""

@app.route('/logout')
@login_required
def logout():
    logout_user()
    flash("logout OK", "info")
    return redirect(url_for('index'))

@app.route("/get_unlocked", methods=["GET"])
@login_required
def get_unlocked():
    user_id = current_user.id
    doc = db.collection("users").document(user_id).get()
    if doc.exists:
        unlocked = doc.to_dict().get("unlocked_dex", [])
        return jsonify({"unlocked_ids": unlocked})
    return jsonify({"unlocked_ids": []})

import re
import traceback
from flask import request, jsonify
from flask_login import login_required, current_user

@app.route("/analyze_trash", methods=["POST"])
@login_required
def analyze_trash():
    file = request.files.get("image")
    if not file:
        return jsonify({"error": "No file uploaded"}), 400

    image_bytes = file.read()

    prompt = """
Please select the category that best matches the object in the image from the list of marine debris types below, and reply in the following format:
【Category】: Name of the category (as listed below)
【Description】: A brief explanation of the item’s common sources, materials, and its environmental impact (about 2–3 lines).

Category List:
1. PET Bottle  
2. Bottle Cap  
3. Aluminum Can  
4. Foil Container  
5. Paper  
6. Cardboard Box  
7. Paper Lunchbox  
8. Cigarette Box  
9. Plastic Spoon  
10. Plastic Fork  
11. Disposable Cup  
12. Plastic Drink Cup  
13. Foam Drink Cup  
14. Plastic Bag  
15. Plastic Straw  
16. Foam Piece  
17. Fishing Net  
18. Buoy  
19. Float Ball  
20. Lighter  
21. Cotton Swab  
22. Cigarette Butt  
23. Flip-flop  
24. Glass Bottle  
25. Glass Shard  
"""

    try:
        response = model.generate_content([
            {"text": prompt},
            {"mime_type": file.mimetype, "data": image_bytes}
        ])
    except Exception as e:
        print("❌ Gemini API Error:")
        traceback.print_exc()
        return jsonify({"error": "Gemini API error"}), 500

    try:
        response_text = response.text.strip()
        print("✅ Gemini response:", response_text)
        match = re.search(r"【Category】[:：]?\s*(\d+\.\s*)?(.*)", response_text)
        if not match:
            print("❌ Unable to extract category")
            return jsonify({"detected": "error"})

        category = match.group(2).strip()
        TRASH_DEX = {
            "PET Bottle": {"id": "001", "image": "/static/dex/001.png"},
            "Bottle Cap": {"id": "002", "image": "/static/dex/002.png"},
            "Aluminum Can": {"id": "003", "image": "/static/dex/003.png"},
            "Foil Container": {"id": "004", "image": "/static/dex/004.png"},
            "Paper": {"id": "005", "image": "/static/dex/005.png"},
            "Cardboard Box": {"id": "006", "image": "/static/dex/006.png"},
            "Paper Lunchbox": {"id": "007", "image": "/static/dex/007.png"},
            "Cigarette Box": {"id": "008", "image": "/static/dex/008.png"},
            "Plastic Spoon": {"id": "009", "image": "/static/dex/009.png"},
            "Plastic Fork": {"id": "010", "image": "/static/dex/010.png"},
            "Disposable Cup": {"id": "011", "image": "/static/dex/011.png"},
            "Plastic Drink Cup": {"id": "012", "image": "/static/dex/012.png"},
            "Foam Drink Cup": {"id": "013", "image": "/static/dex/013.png"},
            "Plastic Bag": {"id": "014", "image": "/static/dex/014.png"},
            "Plastic Straw": {"id": "015", "image": "/static/dex/015.png"},
            "Foam Piece": {"id": "016", "image": "/static/dex/016.png"},
            "Fishing Net": {"id": "017", "image": "/static/dex/017.png"},
            "Buoy": {"id": "018", "image": "/static/dex/018.png"},
            "Float Ball": {"id": "019", "image": "/static/dex/019.png"},
            "Lighter": {"id": "020", "image": "/static/dex/020.png"},
            "Cotton Swab": {"id": "021", "image": "/static/dex/021.png"},
            "Cigarette Butt": {"id": "022", "image": "/static/dex/022.png"},
            "Flip-flop": {"id": "023", "image": "/static/dex/023.png"},
            "Glass Bottle": {"id": "024", "image": "/static/dex/024.png"},
            "Glass Shard": {"id": "025", "image": "/static/dex/025.png"}
        }

        dex = TRASH_DEX.get(category)
        if not dex:
            print(f"❌ '{category}' not found in TRASH_DEX")
            return jsonify({"detected": "error"})

        # 更新用戶資料
        user_ref = db.collection("users").document(current_user.id)
        doc = user_ref.get()
        unlocked = doc.to_dict().get("unlocked_dex", []) if doc.exists else []

        if dex["id"] not in unlocked:
            unlocked.append(dex["id"])
            current_tokens = doc.to_dict().get("tokens", 0)
            user_ref.set({
                "unlocked_dex": unlocked,
                "tokens": current_tokens + 1
            }, merge=True)

        return jsonify({
            "detected": category,
            "unlocked_id": dex["id"],
            "unlocked_name": category,
            "unlocked_image": dex["image"]
        })

    except Exception:
        traceback.print_exc()
        return jsonify({"error": "unexpected server error"}), 500

    
@app.route("/get_token_count")
@login_required
def get_token_count():
    doc = db.collection("users").document(current_user.id).get()
    tokens = doc.to_dict().get("tokens", 0) if doc.exists else 0
    return jsonify({"tokens": tokens})
@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)