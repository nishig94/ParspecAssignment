from flask import Flask, request, render_template
import sqlite3, os

DB_PATH = os.path.join(os.path.dirname(__file__), 'demo.db')
app = Flask(__name__)

def query_db_unsafe(username: str):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    sql = f"SELECT * FROM users WHERE username = '{username}'"  # VULNERABLE
    row = cur.execute(sql).fetchone()
    conn.close()
    return row

def query_db_safe(username: str):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    sql = "SELECT * FROM users WHERE username = ?"
    row = cur.execute(sql, (username,)).fetchone()
    conn.close()
    return row

@app.route('/page1', methods=['GET', 'POST'])
def page1():
    msg = None
    if request.method == 'POST':
        username = request.form.get('username', '')
        row = query_db_unsafe(username)
        msg = 'Login successful (demo).' if row else 'Invalid username.'
    return render_template('page1.html', msg=msg)

@app.route('/page2', methods=['GET', 'POST'])
def page2():
    msg = None
    if request.method == 'POST':
        username = request.form.get('username', '')
        if len(username) > 64:
            msg = 'Input too long.'
        else:
            row = query_db_safe(username)
            msg = 'Login successful (demo).' if row else 'Invalid username.'
    return render_template('page2.html', msg=msg)

@app.route('/')
def index():
    return '<h3>Parspec SQLi demo</h3><ul>' \
           '<li><a href="/page1">Vulnerable login (page1)</a></li>' \
           '<li><a href="/page2">Protected login (page2)</a></li>' \
           '<li>Assignment URLs: /page1.html and /page2.html redirect here</li></ul>'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
