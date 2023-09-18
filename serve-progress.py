#!/usr/bin/env python3

import http.server
import socketserver
from pathlib import Path

status_path = Path('download-model-status.json')

# Define a handler to serve the progress page
class ProgressHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        message = status_path.read_text()
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(message.encode())

    def log_message(self, format, *args):
        pass

# Start the HTTP server in the background
with socketserver.TCPServer(("0.0.0.0", 7850), ProgressHandler) as httpd:
    try:
        httpd.serve_forever()
    finally:
        httpd.shutdown()
