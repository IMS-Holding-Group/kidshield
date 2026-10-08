from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import os
import re
import json
import urllib.request
import urllib.error
from datetime import datetime
from model.text_classifier import TextClassifier

app = Flask(__name__)
CORS(app)

DATABASE = os.path.join(os.path.dirname(__file__), 'database.db')
classifier = TextClassifier()

def init_db():
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            display_name TEXT,
            email TEXT,
            phone TEXT
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS content_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            child_id INTEGER,
            text_content TEXT NOT NULL,
            label TEXT NOT NULL,
            risk_level TEXT NOT NULL DEFAULT 'safe',
            risk_score REAL DEFAULT 0.0,
            confidence REAL NOT NULL,
            reason TEXT,
            explanation TEXT,
            child_name TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id),
            FOREIGN KEY (child_id) REFERENCES children(id)
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS children (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            age INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id),
            UNIQUE(user_id, name)
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            content_log_id INTEGER NOT NULL,
            reason TEXT NOT NULL,
            status TEXT DEFAULT 'new',
            is_read INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id),
            FOREIGN KEY (content_log_id) REFERENCES content_logs(id)
        )
    ''')
    
    try:
        cursor.execute('ALTER TABLE content_logs ADD COLUMN risk_level TEXT DEFAULT "safe"')
    except:
        pass
    
    try:
        cursor.execute('ALTER TABLE content_logs ADD COLUMN child_name TEXT')
    except:
        pass
    
    try:
        cursor.execute('ALTER TABLE alerts ADD COLUMN is_read INTEGER DEFAULT 0')
    except:
        pass
    
    try:
        cursor.execute('ALTER TABLE alerts ADD COLUMN status TEXT DEFAULT "new"')
    except:
        pass
    
    try:
        cursor.execute('ALTER TABLE content_logs ADD COLUMN risk_score REAL DEFAULT 0.0')
    except:
        pass
    for col in ['display_name', 'email', 'phone']:
        try:
            cursor.execute('ALTER TABLE users ADD COLUMN %s TEXT' % col)
        except:
            pass
    
    try:
        cursor.execute('ALTER TABLE content_logs ADD COLUMN explanation TEXT')
    except:
        pass
    try:
        cursor.execute('ALTER TABLE users ADD COLUMN role TEXT DEFAULT \'parent\'')
    except:
        pass
    try:
        cursor.execute('ALTER TABLE users ADD COLUMN parent_id INTEGER')
    except:
        pass
    try:
        cursor.execute('ALTER TABLE content_logs ADD COLUMN source_app TEXT')
    except:
        pass
    try:
        cursor.execute('ALTER TABLE content_logs ADD COLUMN source_child_user_id INTEGER')
    except:
        pass

    cursor.execute('SELECT COUNT(*) FROM users')
    if cursor.fetchone()[0] == 0:
        cursor.execute('INSERT INTO users (username, password) VALUES (?, ?)', ('admin', 'admin123'))
        conn.commit()
    cursor.execute('SELECT id FROM users WHERE username = ?', ('parent_demo',))
    if not cursor.fetchone():
        cursor.execute(
            'INSERT INTO users (username, password, display_name, role) VALUES (?, ?, ?, ?)',
            ('parent_demo', 'parent123', 'ولي أمر (تجربة)', 'parent'),
        )
    cursor.execute('SELECT id FROM users WHERE username = ?', ('child_demo',))
    if not cursor.fetchone():
        cursor.execute('SELECT id FROM users WHERE username = ?', ('parent_demo',))
        prow = cursor.fetchone()
        pid = prow[0] if prow else 1
        cursor.execute(
            'INSERT INTO users (username, password, display_name, role, parent_id) VALUES (?, ?, ?, ?, ?)',
            ('child_demo', 'child123', 'طفل (تجربة)', 'child', pid),
        )
    
    conn.commit()
    conn.close()

def _fetch_media_metadata(url, media_type):
    # يوتيوب: استخدم oEmbed أولاً (يعمل دون حظر)
    if 'youtube.com' in url or 'youtu.be' in url:
        vid_match = re.search(r'(?:v=|/)([a-zA-Z0-9_-]{11})', url)
        if vid_match:
            oembed_url = f"https://www.youtube.com/oembed?url=https://youtube.com/watch?v={vid_match.group(1)}&format=json"
            try:
                req = urllib.request.Request(oembed_url, headers={'User-Agent': 'KidShield/1.0'})
                with urllib.request.urlopen(req, timeout=8) as r:
                    data = json.loads(r.read().decode())
                    title = data.get('title', '')
                    author = data.get('author_name', '')
                    combined = f"{title} {author}".strip()
                    if combined:
                        return combined
            except Exception:
                pass

    # باقي المواقع: جلب الصفحة
    try:
        from bs4 import BeautifulSoup
        req = urllib.request.Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        })
        with urllib.request.urlopen(req, timeout=10) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
        soup = BeautifulSoup(html, 'html.parser')
        title, description = '', ''
        for meta in soup.find_all('meta'):
            prop = (meta.get('property') or meta.get('name') or '').lower()
            content = meta.get('content', '')
            if 'title' in prop:
                title = content or title
            if 'description' in prop:
                description = content or description
        combined = f"{title}\n{description}".strip()
        return combined if combined else 'تم جلب الرابط - النص غير متاح'
    except Exception as e:
        return f'رابط: {url[:50]}... (جلب النص فشل: {str(e)[:80]})'

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'البيانات مطلوبة'}), 400
        
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
        
        if not username or not password:
            return jsonify({'success': False, 'message': 'اسم المستخدم وكلمة المرور مطلوبان'}), 400
        
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        cursor.execute(
            '''SELECT id, role, parent_id, COALESCE(display_name, username) as dn
               FROM users WHERE username = ? AND password = ?''',
            (username, password),
        )
        user = cursor.fetchone()
        
        if not user:
            cursor.execute('SELECT COUNT(*) FROM users')
            user_count = cursor.fetchone()[0]
            conn.close()
            
            if user_count == 0:
                return jsonify({
                    'success': False, 
                    'message': 'لا يوجد مستخدمين. يرجى التأكد من تهيئة قاعدة البيانات'
                }), 401
            
            return jsonify({
                'success': False, 
                'message': 'اسم المستخدم أو كلمة المرور غير صحيحة. جرّب: parent_demo / parent123 أو child_demo / child123'
            }), 401
        
        conn.close()
        role = (user[1] or 'parent').lower()
        if role not in ('parent', 'child'):
            role = 'parent'
        return jsonify({
            'success': True,
            'user_id': user[0],
            'role': role,
            'parent_id': user[2],
            'display_name': user[3],
            'message': 'تم تسجيل الدخول بنجاح',
        })
    except Exception as e:
        return jsonify({'success': False, 'message': f'خطأ في تسجيل الدخول: {str(e)}'}), 500

@app.route('/analyze_text', methods=['POST'])
def analyze_text():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'البيانات مطلوبة'}), 400
        
        text = data.get('text', '').strip()
        user_id = data.get('user_id')
        child_id = data.get('child_id')
        child_name = data.get('child_name', '').strip()
        source_app = (data.get('source_app') or '').strip() or None
        save_only = data.get('save_only', False)
        
        if not text:
            return jsonify({'success': False, 'message': 'النص مطلوب ولا يمكن أن يكون فارغاً'}), 400
        
        if len(text) < 2:
            return jsonify({'success': False, 'message': 'النص قصير جداً (أقل من حرفين)'}), 400
        
        if not user_id:
            return jsonify({'success': False, 'message': 'معرف المستخدم مطلوب'}), 400
        
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        cursor.execute(
            'SELECT role, parent_id, username FROM users WHERE id = ?',
            (int(user_id),),
        )
        urow = cursor.fetchone()
        effective_user_id = int(user_id)
        source_child_user_id = None
        urole = (urow[0] or 'parent') if urow else 'parent'
        uparent = urow[1] if urow else None
        uusername = (urow[2] or '') if urow else ''
        if urole == 'child' and uparent:
            effective_user_id = int(uparent)
            source_child_user_id = int(user_id)
            if not child_name:
                child_name = uusername

        if child_id:
            cursor.execute(
                'SELECT name FROM children WHERE id = ? AND user_id = ?',
                (child_id, effective_user_id),
            )
            child = cursor.fetchone()
            if child:
                child_name = child[0]
        
        if save_only:
            cursor.execute('''
                INSERT INTO content_logs (user_id, child_id, text_content, label, risk_level, risk_score, confidence, reason, child_name, source_app, source_child_user_id, explanation)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (effective_user_id, child_id, text, 'safe', 'low', 0.0, 0.0, 'تم الحفظ فقط', child_name, source_app, source_child_user_id, 'تم حفظ النص دون تحليل'))
            log_id = cursor.lastrowid
            conn.commit()
            conn.close()
            return jsonify({
                'success': True,
                'result': {'label': 'safe', 'risk_level': 'low', 'risk_score': 0.0, 'confidence': 0.0, 'reason': 'تم الحفظ فقط', 'explanation': 'تم حفظ النص دون تحليل'},
                'log_id': log_id
            })
        
        if not classifier.load_model():
            conn.close()
            return jsonify({'success': False, 'message': 'النموذج غير مدرب. يرجى تدريب النموذج أولاً'}), 500
        
        result = classifier.predict(text)
        
        risk_level = result.get('risk_level', 'low')
        if risk_level == 'safe':
            risk_level = 'low'
        risk_score = result.get('risk_score', result.get('confidence', 0.0))
        explanation = result.get('explanation', result.get('reason', ''))
        
        cursor.execute('''
            INSERT INTO content_logs (user_id, child_id, text_content, label, risk_level, risk_score, confidence, reason, explanation, child_name, source_app, source_child_user_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (effective_user_id, child_id, text, result['label'], risk_level, risk_score, result['confidence'], result['reason'], explanation, child_name, source_app, source_child_user_id))
        
        log_id = cursor.lastrowid
        
        if risk_level in ['medium', 'high']:
            cursor.execute('''
                INSERT INTO alerts (user_id, content_log_id, reason, status, is_read)
                VALUES (?, ?, ?, 'new', 0)
            ''', (effective_user_id, log_id, result['reason']))
        
        conn.commit()
        conn.close()
        
        return jsonify({
            'success': True,
            'result': result,
            'log_id': log_id
        })
    except Exception as e:
        return jsonify({'success': False, 'message': f'خطأ في التحليل: {str(e)}'}), 500

@app.route('/alerts', methods=['GET'])
def get_alerts():
    user_id = request.args.get('user_id', type=int)
    
    if not user_id:
        return jsonify({'success': False, 'message': 'معرف المستخدم مطلوب'}), 400
    
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT a.id, cl.text_content, cl.risk_level, cl.risk_score, a.reason, a.status, a.is_read, a.created_at, cl.child_name, cl.source_app, cl.explanation
        FROM alerts a
        JOIN content_logs cl ON a.content_log_id = cl.id
        WHERE a.user_id = ?
        ORDER BY a.created_at DESC
    ''', (user_id,))
    
    alerts = []
    for row in cursor.fetchall():
        alerts.append({
            'id': row[0],
            'text': row[1],
            'risk_level': row[2],
            'risk_score': row[3],
            'reason': row[4],
            'status': row[5] or 'new',
            'is_read': bool(row[6]),
            'date': row[7],
            'child_name': row[8],
            'source_app': row[9],
            'explanation': row[10],
        })
    
    conn.close()
    
    return jsonify({'success': True, 'alerts': alerts})

@app.route('/alerts/<int:alert_id>/status', methods=['PUT'])
def update_alert_status(alert_id):
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'البيانات مطلوبة'}), 400
        
        status = data.get('status', 'reviewed')
        if status not in ['new', 'reviewed', 'ignored']:
            return jsonify({'success': False, 'message': 'حالة غير صحيحة'}), 400
        
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        cursor.execute('UPDATE alerts SET status = ?, is_read = ? WHERE id = ?', 
                      (status, 1 if status == 'reviewed' else 0, alert_id))
        
        if cursor.rowcount == 0:
            conn.close()
            return jsonify({'success': False, 'message': 'التنبيه غير موجود'}), 404
        
        conn.commit()
        conn.close()
        return jsonify({'success': True, 'message': 'تم تحديث حالة التنبيه'})
    except Exception as e:
        return jsonify({'success': False, 'message': f'خطأ: {str(e)}'}), 500

@app.route('/content_logs', methods=['GET'])
def get_content_logs():
    user_id = request.args.get('user_id', type=int)
    child_id = request.args.get('child_id', type=int)
    child_name = request.args.get('child_name', type=str)
    limit = request.args.get('limit', type=int, default=100)
    
    if not user_id:
        return jsonify({'success': False, 'message': 'معرف المستخدم مطلوب'}), 400
    
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    query = '''
        SELECT id, text_content, label, risk_level, risk_score, confidence, reason, explanation, child_name, created_at, source_app
        FROM content_logs
        WHERE user_id = ?
    '''
    params = [user_id]
    
    if child_id:
        query += ' AND child_id = ?'
        params.append(child_id)
    elif child_name:
        query += ' AND child_name = ?'
        params.append(child_name)
    
    query += ' ORDER BY created_at DESC LIMIT ?'
    params.append(limit)
    
    cursor.execute(query, params)
    
    logs = []
    for row in cursor.fetchall():
        logs.append({
            'id': row[0],
            'text': row[1],
            'label': row[2],
            'risk_level': row[3] or 'low',
            'risk_score': row[4] or row[5],
            'confidence': row[5],
            'reason': row[6],
            'explanation': row[7],
            'child_name': row[8],
            'date': row[9],
            'source_app': row[10],
        })
    
    conn.close()
    
    grouped_logs = _group_logs_by_date(logs)
    
    return jsonify({'success': True, 'logs': logs, 'grouped_by_date': grouped_logs})

def _group_logs_by_date(logs):
    from datetime import datetime
    grouped = {}
    
    for log in logs:
        date_str = log['date']
        try:
            date_obj = datetime.strptime(date_str.split()[0], '%Y-%m-%d')
            date_key = date_obj.strftime('%Y-%m-%d')
            
            if date_key not in grouped:
                grouped[date_key] = {
                    'date': date_key,
                    'count': 0,
                    'harmful_count': 0,
                    'logs': []
                }
            
            grouped[date_key]['count'] += 1
            if log['risk_level'] in ['medium', 'high']:
                grouped[date_key]['harmful_count'] += 1
            
            grouped[date_key]['logs'].append(log)
        except:
            pass
    
    return list(grouped.values())

@app.route('/content_logs/<int:log_id>', methods=['DELETE'])
def delete_content_log(log_id):
    user_id = request.args.get('user_id', type=int)
    if not user_id:
        return jsonify({'success': False, 'message': 'معرف المستخدم مطلوب'}), 400
    
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    cursor.execute('SELECT user_id FROM content_logs WHERE id = ?', (log_id,))
    row = cursor.fetchone()
    if not row:
        conn.close()
        return jsonify({'success': False, 'message': 'السجل غير موجود'}), 404
    
    if row[0] != user_id:
        conn.close()
        return jsonify({'success': False, 'message': 'غير مصرح'}), 403
    
    cursor.execute('DELETE FROM alerts WHERE content_log_id = ?', (log_id,))
    cursor.execute('DELETE FROM content_logs WHERE id = ?', (log_id,))
    conn.commit()
    conn.close()
    
    return jsonify({'success': True, 'message': 'تم الحذف بنجاح'})

@app.route('/children', methods=['GET', 'POST'])
def manage_children():
    if request.method == 'GET':
        user_id = request.args.get('user_id', type=int)
        
        if not user_id:
            return jsonify({'success': False, 'message': 'معرف المستخدم مطلوب'}), 400
        
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT c.id, c.name, c.age, COUNT(cl.id) as analysis_count
            FROM children c
            LEFT JOIN content_logs cl ON c.id = cl.child_id
            WHERE c.user_id = ?
            GROUP BY c.id, c.name, c.age
            ORDER BY c.created_at DESC
        ''', (user_id,))
        
        children = []
        for row in cursor.fetchall():
            children.append({
                'id': row[0],
                'name': row[1],
                'age': row[2],
                'analysis_count': row[3]
            })
        
        conn.close()
        return jsonify({'success': True, 'children': children})
    
    elif request.method == 'POST':
        try:
            data = request.get_json()
            if not data:
                return jsonify({'success': False, 'message': 'البيانات مطلوبة'}), 400
            
            user_id = data.get('user_id')
            name = data.get('name', '').strip()
            age = data.get('age')
            
            if not user_id:
                return jsonify({'success': False, 'message': 'معرف المستخدم مطلوب'}), 400
            
            if not name or len(name) < 2:
                return jsonify({'success': False, 'message': 'اسم الطفل مطلوب (أقل من حرفين)'}), 400
            
            conn = sqlite3.connect(DATABASE)
            cursor = conn.cursor()
            
            try:
                cursor.execute('''
                    INSERT INTO children (user_id, name, age)
                    VALUES (?, ?, ?)
                ''', (user_id, name, age))
                child_id = cursor.lastrowid
                conn.commit()
                conn.close()
                return jsonify({'success': True, 'child_id': child_id, 'message': 'تم إضافة الطفل بنجاح'})
            except sqlite3.IntegrityError:
                conn.close()
                return jsonify({'success': False, 'message': 'الطفل موجود مسبقاً'}), 400
        except Exception as e:
            return jsonify({'success': False, 'message': f'خطأ: {str(e)}'}), 500

@app.route('/children/<int:child_id>', methods=['DELETE'])
def delete_child(child_id):
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'success': False, 'message': 'معرف المستخدم مطلوب'}), 400
        
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        cursor.execute('DELETE FROM children WHERE id = ? AND user_id = ?', (child_id, user_id))
        
        if cursor.rowcount == 0:
            conn.close()
            return jsonify({'success': False, 'message': 'الطفل غير موجود'}), 404
        
        conn.commit()
        conn.close()
        return jsonify({'success': True, 'message': 'تم حذف الطفل بنجاح'})
    except Exception as e:
        return jsonify({'success': False, 'message': f'خطأ: {str(e)}'}), 500

@app.route('/statistics', methods=['GET'])
def get_statistics():
    user_id = request.args.get('user_id', type=int)
    
    if not user_id:
        return jsonify({'success': False, 'message': 'معرف المستخدم مطلوب'}), 400
    
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()

    def _top_apps(days):
        time_clause = f" AND created_at >= datetime('now', '-{int(days)} days')"
        cursor.execute(
            f'''SELECT COALESCE(source_app, 'غير محدد'), COUNT(*) FROM content_logs
            WHERE user_id = ? {time_clause}
            GROUP BY 1 ORDER BY 2 DESC LIMIT 8''',
            (user_id,),
        )
        total_by_app = [{'app': r[0], 'count': r[1]} for r in cursor.fetchall()]
        cursor.execute(
            f'''SELECT COALESCE(source_app, 'غير محدد'), COUNT(*) FROM content_logs
            WHERE user_id = ? {time_clause} AND risk_level IN ('high', 'medium')
            GROUP BY 1 ORDER BY 2 DESC LIMIT 8''',
            (user_id,),
        )
        harm_by_app = [{'app': r[0], 'count': r[1]} for r in cursor.fetchall()]
        return total_by_app, harm_by_app

    cursor.execute('SELECT COUNT(*) FROM content_logs WHERE user_id = ?', (user_id,))
    total_logs = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(*) FROM content_logs WHERE user_id = ? AND risk_level = ?', (user_id, 'high'))
    high_risk_count = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(*) FROM content_logs WHERE user_id = ? AND risk_level = ?', (user_id, 'medium'))
    medium_risk_count = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(*) FROM content_logs WHERE user_id = ? AND risk_level = ?', (user_id, 'low'))
    low_risk_count = cursor.fetchone()[0]
    
    harmful_count = high_risk_count + medium_risk_count
    warning_count = medium_risk_count
    safe_count = low_risk_count
    
    cursor.execute('SELECT COUNT(*) FROM alerts WHERE user_id = ?', (user_id,))
    alerts_count = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(*) FROM alerts WHERE user_id = ? AND is_read = 0', (user_id,))
    unread_alerts = cursor.fetchone()[0]
    
    cursor.execute('''
        SELECT risk_level, COUNT(*) as count 
        FROM content_logs 
        WHERE user_id = ? AND risk_level IN ('high', 'medium')
        GROUP BY risk_level
        ORDER BY count DESC
        LIMIT 1
    ''', (user_id,))
    most_common_risk = cursor.fetchone()
    
    cursor.execute('''
        SELECT child_name, COUNT(*) as count
        FROM content_logs
        WHERE user_id = ? AND risk_level IN ('high', 'medium')
        AND child_name IS NOT NULL AND child_name != ''
        GROUP BY child_name
        ORDER BY count DESC
        LIMIT 1
    ''', (user_id,))
    most_at_risk_child = cursor.fetchone()
    
    cursor.execute('''
        SELECT COUNT(*) FROM content_logs 
        WHERE user_id = ? AND created_at >= datetime('now', '-7 days')
        AND risk_level IN ('high', 'medium')
    ''', (user_id,))
    last_7_days_harmful = cursor.fetchone()[0]
    
    cursor.execute('''
        SELECT COUNT(*) FROM content_logs 
        WHERE user_id = ? AND created_at >= datetime('now', '-7 days')
    ''', (user_id,))
    last_7_days_total = cursor.fetchone()[0]
    
    cursor.execute('''
        SELECT AVG(risk_score) FROM content_logs 
        WHERE user_id = ? AND risk_level IN ('high', 'medium')
    ''', (user_id,))
    avg_risk_score = cursor.fetchone()[0] or 0
    
    cursor.execute('''
        SELECT reason, COUNT(*) as count 
        FROM alerts 
        WHERE user_id = ?
        GROUP BY reason
        ORDER BY count DESC
        LIMIT 5
    ''', (user_id,))
    
    top_reasons = []
    for row in cursor.fetchall():
        top_reasons.append({
            'reason': row[0],
            'count': row[1]
        })
    
    apps_week_usage, apps_week_risk = _top_apps(7)
    apps_month_usage, apps_month_risk = _top_apps(30)
    
    cursor.execute('''
        SELECT COUNT(*) FROM content_logs
        WHERE user_id = ? AND created_at >= datetime('now', '-30 days')
        AND risk_level IN ('high', 'medium')
    ''', (user_id,))
    last_30_days_harmful = cursor.fetchone()[0]
    cursor.execute('''
        SELECT COUNT(*) FROM content_logs
        WHERE user_id = ? AND created_at >= datetime('now', '-30 days')
    ''', (user_id,))
    last_30_days_total = cursor.fetchone()[0]
    
    conn.close()
    avg_c = round(float(avg_risk_score) * 100, 1) if avg_risk_score else 0.0
    return jsonify({
        'success': True,
        'statistics': {
            'total_logs': total_logs,
            'harmful_count': harmful_count,
            'warning_count': warning_count,
            'safe_count': safe_count,
            'alerts_count': alerts_count,
            'unread_alerts': unread_alerts,
            'harmful_percentage': round((harmful_count / total_logs * 100) if total_logs > 0 else 0, 2),
            'warning_percentage': round((warning_count / total_logs * 100) if total_logs > 0 else 0, 2),
            'safe_percentage': round((safe_count / total_logs * 100) if total_logs > 0 else 0, 2),
            'avg_risk_score': round(avg_risk_score, 2),
            'avg_confidence': avg_c,
            'most_common_risk': most_common_risk[0] if most_common_risk else 'low',
            'most_at_risk_child': most_at_risk_child[0] if most_at_risk_child else None,
            'last_7_days_harmful': last_7_days_harmful,
            'last_7_days_total': last_7_days_total,
            'last_30_days_harmful': last_30_days_harmful,
            'last_30_days_total': last_30_days_total,
            'weekly_report': {
                'period_days': 7,
                'total_logs': last_7_days_total,
                'harmful_logs': last_7_days_harmful,
                'top_apps_by_usage': apps_week_usage,
                'top_apps_by_risk': apps_week_risk,
            },
            'monthly_report': {
                'period_days': 30,
                'total_logs': last_30_days_total,
                'harmful_logs': last_30_days_harmful,
                'top_apps_by_usage': apps_month_usage,
                'top_apps_by_risk': apps_month_risk,
            },
            'top_reasons': top_reasons
        }
    })

@app.route('/monitoring/status', methods=['GET'])
def get_monitoring_status():
    user_id = request.args.get('user_id', type=int)
    
    if not user_id:
        return jsonify({'success': False, 'message': 'معرف المستخدم مطلوب'}), 400
    
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT COUNT(*) FROM content_logs 
        WHERE user_id = ? AND created_at >= datetime('now', '-1 hour')
        AND risk_level IN ('high', 'medium')
    ''', (user_id,))
    recent_alerts = cursor.fetchone()[0]
    
    conn.close()
    
    return jsonify({
        'success': True,
        'is_active': True,
        'recent_alerts': recent_alerts,
        'message': 'المراقبة التلقائية نشطة'
    })

@app.route('/user/<int:user_id>/profile', methods=['GET', 'PUT'])
def user_profile(user_id):
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    
    if request.method == 'GET':
        cursor.execute(
            'SELECT username, display_name, email, phone FROM users WHERE id = ?',
            (user_id,)
        )
        row = cursor.fetchone()
        conn.close()
        if not row:
            return jsonify({'success': False, 'message': 'المستخدم غير موجود'}), 404
        return jsonify({
            'success': True,
            'username': row[0],
            'display_name': row[1] or row[0],
            'email': row[2] or '',
            'phone': row[3] or ''
        })
    
    elif request.method == 'PUT':
        try:
            data = request.get_json() or {}
            display_name = data.get('display_name', '').strip()
            email = data.get('email', '').strip()
            phone = data.get('phone', '').strip()
            
            cursor.execute('''
                UPDATE users SET display_name = ?, email = ?, phone = ?
                WHERE id = ?
            ''', (display_name or None, email or None, phone or None, user_id))
            
            if cursor.rowcount == 0:
                conn.close()
                return jsonify({'success': False, 'message': 'المستخدم غير موجود'}), 404
            
            conn.commit()
            conn.close()
            return jsonify({'success': True, 'message': 'تم تحديث الملف الشخصي بنجاح'})
        except Exception as e:
            conn.close()
            return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/analyze_media', methods=['POST'])
def analyze_media():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'البيانات مطلوبة'}), 400
        
        url = data.get('url', '').strip()
        media_type = data.get('media_type', 'video')
        user_id = data.get('user_id')
        child_id = data.get('child_id')
        child_name = data.get('child_name', '').strip()
        source_app = (data.get('source_app') or '').strip() or None
        save_only = data.get('save_only', False)
        
        if not url:
            return jsonify({'success': False, 'message': 'رابط الفيديو/اللعبة مطلوب'}), 400
        
        if not user_id:
            return jsonify({'success': False, 'message': 'معرف المستخدم مطلوب'}), 400
        
        # التحقق من صحة الرابط - يدعم روابط يوتيوب ومتاجر الألعاب
        if not re.match(r'^https?://[^\s]+', url):
            return jsonify({'success': False, 'message': 'رابط غير صحيح. مثال: https://youtube.com/watch?v=xxxx'}), 400
        allowed_domains = ['youtube.com', 'youtu.be', 'm.youtube.com', 'www.youtube.com',
                          'play.google.com', 'apps.apple.com', 'apps.apple.com',
                          'store.steampowered.com', 'store.steam.com', 'epicgames.com',
                          'roblox.com', 'itch.io']
        if not any(d in url.lower() for d in allowed_domains):
            return jsonify({
                'success': False,
                'message': 'يدعم: يوتيوب، جوجل بلاي، آب ستور، ستيم، إيبك، روبلوكس'
            }), 400
        
        text_content = _fetch_media_metadata(url, media_type)
        if not source_app:
            if 'youtu' in url.lower():
                source_app = 'يوتيوب / فيديو'
            elif 'play.google' in url.lower() or 'apple.com' in url.lower():
                source_app = 'متجر تطبيقات'
            else:
                source_app = f'رابط {media_type}'
        
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        cursor.execute(
            'SELECT role, parent_id, username FROM users WHERE id = ?',
            (int(user_id),),
        )
        urow = cursor.fetchone()
        effective_user_id = int(user_id)
        source_child_user_id = None
        urole = (urow[0] or 'parent') if urow else 'parent'
        uparent = urow[1] if urow else None
        uusername = (urow[2] or '') if urow else ''
        if urole == 'child' and uparent:
            effective_user_id = int(uparent)
            source_child_user_id = int(user_id)
            if not child_name:
                child_name = uusername
        
        if child_id:
            cursor.execute('SELECT name FROM children WHERE id = ? AND user_id = ?', (child_id, effective_user_id))
            c = cursor.fetchone()
            if c:
                child_name = c[0]
        
        full_text = f"[{media_type.upper()}] {url}\n\n{text_content}"
        
        if save_only:
            cursor.execute('''
                INSERT INTO content_logs (user_id, child_id, text_content, label, risk_level, risk_score, confidence, reason, child_name, source_app, source_child_user_id, explanation)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (effective_user_id, child_id, full_text, 'safe', 'low', 0.0, 0.0, 'تم الحفظ فقط', child_name, source_app, source_child_user_id, 'تم الحفظ فقط'))
            log_id = cursor.lastrowid
            conn.commit()
            conn.close()
            return jsonify({
                'success': True,
                'result': {'label': 'safe', 'risk_level': 'low', 'reason': 'تم الحفظ فقط', 'source_url': url, 'extracted_text': text_content[:200]},
                'log_id': log_id
            })
        
        if not classifier.load_model():
            conn.close()
            return jsonify({'success': False, 'message': 'النموذج غير مدرب'}), 500
        
        result = classifier.predict(text_content)
        risk_level = result.get('risk_level', 'low')
        if risk_level == 'safe':
            risk_level = 'low'
        risk_score = result.get('risk_score', result.get('confidence', 0.0))
        explanation = result.get('explanation', result.get('reason', ''))
        
        cursor.execute('''
            INSERT INTO content_logs (user_id, child_id, text_content, label, risk_level, risk_score, confidence, reason, explanation, child_name, source_app, source_child_user_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (effective_user_id, child_id, full_text, result['label'], risk_level, risk_score, result['confidence'], result['reason'], explanation, child_name, source_app, source_child_user_id))
        
        log_id = cursor.lastrowid
        
        if risk_level in ['medium', 'high']:
            cursor.execute('''
                INSERT INTO alerts (user_id, content_log_id, reason, status, is_read)
                VALUES (?, ?, ?, 'new', 0)
            ''', (effective_user_id, log_id, result['reason']))
        
        conn.commit()
        conn.close()
        
        result['source_url'] = url
        result['extracted_text'] = text_content[:300]
        result['media_type'] = media_type
        
        return jsonify({'success': True, 'result': result, 'log_id': log_id})
    except Exception as e:
        return jsonify({'success': False, 'message': f'خطأ في التحليل: {str(e)}'}), 500

@app.route('/false_positives', methods=['POST'])
def report_false_positive():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'البيانات مطلوبة'}), 400
        
        log_id = data.get('log_id')
        user_id = data.get('user_id')
        reason = data.get('reason', '').strip()
        
        if not log_id or not user_id:
            return jsonify({'success': False, 'message': 'معرف السجل والمستخدم مطلوبان'}), 400
        
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        cursor.execute('''
            UPDATE content_logs 
            SET risk_level = 'low', label = 'safe'
            WHERE id = ? AND user_id = ?
        ''', (log_id, user_id))
        
        if cursor.rowcount == 0:
            conn.close()
            return jsonify({'success': False, 'message': 'السجل غير موجود'}), 404
        
        cursor.execute('''
            DELETE FROM alerts WHERE content_log_id = ?
        ''', (log_id,))
        
        conn.commit()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': 'تم الإبلاغ عن الاكتشاف الخاطئ بنجاح'
        })
    except Exception as e:
        return jsonify({'success': False, 'message': f'خطأ: {str(e)}'}), 500

if __name__ == '__main__':
    init_db()
    classifier.load_model()
    print("="*50)
    print("KidShield Backend Server")
    print("="*50)
    print("Server running on http://0.0.0.0:5000")
    print("API Documentation:")
    print("  POST /login - تسجيل الدخول")
    print("  POST /analyze_text - تحليل النص")
    print("  GET /alerts - الحصول على التنبيهات")
    print("  GET /content_logs - سجل المحتوى")
    print("  GET /statistics - الإحصائيات")
    print("  GET /children - قائمة الأطفال")
    print("  POST /children - إضافة طفل")
    print("="*50)
    app.run(host='0.0.0.0', port=5000, debug=True)
