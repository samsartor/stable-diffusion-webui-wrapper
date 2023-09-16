from multiprocessing import Process

def run_server(title, statusfile):
    import http.server
    import socketserver

    # Define a handler to serve the progress page
    class ProgressHandler(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):
            message = statusfile.read_text()
            html_to_serve = f"""
                <!DOCTYPE html>
                <html>
                <head>
                     <title>{title}</title>
                     <script>
                        setTimeout(() => location.reload(), 5000);
                    </script>
                </head>
                <body>
                    {message}
                </body>
                </html>
                """
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(html_to_serve.encode())

        def log_message(self, format, *args):
            pass

    # Start the HTTP server in the background
    with socketserver.TCPServer(("0.0.0.0", 7860), ProgressHandler) as httpd:
        try:
            httpd.serve_forever()
        finally:
            httpd.shutdown()

def ready_server(*args):
    return Process(target=run_server, args=args)
