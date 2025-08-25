import sqlite3, os
DB_PATH = os.path.join(os.path.dirname(__file__), 'demo.db')

conn = sqlite3.connect(DB_PATH)
c = conn.cursor()
c.execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)')
c.execute('DELETE FROM users')
c.executemany('INSERT INTO users (username, password) VALUES (?, ?)', [
    ('admin', 'admin123'),
    ('alice', 'wonderland'),
    ('bob',   'builder'),
])
conn.commit()
conn.close()
print('DB ready at', DB_PATH)
