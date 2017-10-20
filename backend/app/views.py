from . import app
from flask import jsonify

@app.route('/spellings')
def index():
  return jsonify(["accident", "actual", "address", "answer"])
