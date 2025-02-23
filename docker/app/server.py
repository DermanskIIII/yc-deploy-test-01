import http.server
import socketserver
import subprocess
import os

PORT = 80
SCRIPT_PATH = "./workload.sh"

class MyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        process = subprocess.Popen([SCRIPT_PATH], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = process.communicate()
        return_code = process.returncode

        if return_code == 0:
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(stdout)
        else:
            self.send_response(500)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()

Handler = MyHandler
with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"serving at port {PORT}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("Shutting down server...")
        httpd.server_close()