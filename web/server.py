#!/usr/bin/env python3
"""
Backend pour Knights Network Admin Panel.
Proxy les requetes vers l'API Ergo sans exposer le token.
"""

import os
import json
import re
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse, parse_qs

# Configuration
ERGO_API_URL = os.environ.get('ERGO_API_URL', 'http://ergo:8089')
ERGO_API_TOKEN = os.environ.get('ERGO_API_TOKEN', '')
PORT = int(os.environ.get('PORT', 8080))


class AdminHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory='.')

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        # Routes HTML
        if path == '/' or path == '/register':
            self.serve_file('register.html')
        elif path == '/admin' or path == '/admin/':
            self.serve_file('admin.html')
        elif path == '/admin/accounts' or path == '/admin/accounts/':
            self.serve_file('accounts.html')
        elif path.startswith('/admin/accounts/'):
            self.serve_file('account-detail.html')
        # Routes API
        elif path == '/api/status':
            self.handle_status()
        elif path == '/api/accounts':
            self.handle_accounts_list()
        elif path.startswith('/api/accounts/'):
            account_name = path.replace('/api/accounts/', '').strip('/')
            self.handle_account_details(account_name)
        # Fichiers statiques
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == '/api/register':
            self.handle_registration()
        elif self.path == '/api/rehash':
            self.handle_rehash()
        else:
            self.send_error(404, 'Not Found')

    def serve_file(self, filename):
        """Sert un fichier HTML."""
        try:
            with open(filename, 'rb') as f:
                content = f.read()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', len(content))
            self.end_headers()
            self.wfile.write(content)
        except FileNotFoundError:
            self.send_error(404, 'File not found')

    def handle_registration(self):
        """Gere l'inscription d'un nouveau compte."""
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            data = json.loads(body.decode('utf-8'))

            account_name = data.get('accountName', '').strip()
            password = data.get('password', '')

            if not account_name or not password:
                self.send_json_response(400, {'error': 'Nom d\'utilisateur et mot de passe requis'})
                return

            if not re.match(r'^[a-zA-Z0-9_-]+$', account_name):
                self.send_json_response(400, {'error': 'Nom d\'utilisateur invalide'})
                return

            if len(account_name) < 2 or len(account_name) > 32:
                self.send_json_response(400, {'error': 'Nom d\'utilisateur: 2-32 caracteres'})
                return

            if len(password) < 8:
                self.send_json_response(400, {'error': 'Mot de passe: minimum 8 caracteres'})
                return

            result = self.call_ergo_api('/v1/saregister', {
                'accountName': account_name,
                'passphrase': password
            })

            if result['success']:
                self.send_json_response(200, {'message': 'Compte cree avec succes'})
            else:
                error_msg = result.get('error', 'Erreur inconnue')
                if 'already exists' in error_msg.lower() or 'account exists' in error_msg.lower():
                    error_msg = 'Ce nom d\'utilisateur est deja pris'
                self.send_json_response(400, {'error': error_msg})

        except json.JSONDecodeError:
            self.send_json_response(400, {'error': 'JSON invalide'})
        except Exception as e:
            print(f'Registration error: {e}')
            self.send_json_response(500, {'error': 'Erreur interne du serveur'})

    def handle_status(self):
        """Retourne le statut du serveur Ergo."""
        result = self.call_ergo_api('/v1/status', {})
        if result.get('success'):
            self.send_json_response(200, result)
        else:
            self.send_json_response(500, {'error': result.get('error', 'Erreur')})

    def handle_accounts_list(self):
        """Retourne la liste des comptes."""
        result = self.call_ergo_api('/v1/account_list', {})
        if result.get('success'):
            self.send_json_response(200, result)
        else:
            self.send_json_response(500, {'error': result.get('error', 'Erreur')})

    def handle_account_details(self, account_name):
        """Retourne les details d'un compte."""
        if not account_name:
            self.send_json_response(400, {'error': 'Nom de compte requis'})
            return

        result = self.call_ergo_api('/v1/account_details', {
            'accountName': account_name
        })
        if result.get('success'):
            self.send_json_response(200, result)
        else:
            self.send_json_response(404, {'error': result.get('error', 'Compte non trouve')})

    def handle_rehash(self):
        """Recharge la configuration du serveur Ergo."""
        result = self.call_ergo_api('/v1/rehash', {})
        if result.get('success'):
            self.send_json_response(200, {'message': 'Configuration rechargee'})
        else:
            self.send_json_response(500, {'error': result.get('error', 'Erreur lors du rehash')})

    def call_ergo_api(self, endpoint, data):
        """Appelle l'API Ergo."""
        url = f'{ERGO_API_URL}{endpoint}'

        payload = json.dumps(data).encode('utf-8')

        headers = {
            'Authorization': f'Bearer {ERGO_API_TOKEN}',
            'Content-Type': 'application/json'
        }

        try:
            req = Request(url, data=payload, headers=headers, method='POST')
            with urlopen(req, timeout=10) as response:
                response_data = json.loads(response.read().decode('utf-8'))
                response_data['success'] = True
                return response_data
        except HTTPError as e:
            error_body = e.read().decode('utf-8')
            try:
                error_data = json.loads(error_body)
                return {'success': False, 'error': error_data.get('error', f'Erreur {e.code}')}
            except:
                return {'success': False, 'error': f'Erreur {e.code}'}
        except URLError as e:
            return {'success': False, 'error': 'Impossible de contacter le serveur IRC'}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def send_json_response(self, status_code, data):
        """Envoie une reponse JSON."""
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def do_OPTIONS(self):
        """Gere les requetes CORS preflight."""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()


def main():
    if not ERGO_API_TOKEN:
        print('ERREUR: ERGO_API_TOKEN non defini')
        exit(1)

    server = HTTPServer(('0.0.0.0', PORT), AdminHandler)
    print(f'Knights Network Admin demarre sur le port {PORT}')
    print(f'API Ergo: {ERGO_API_URL}')
    print(f'Routes:')
    print(f'  /register       - Page d\'inscription')
    print(f'  /admin          - Dashboard admin')
    print(f'  /admin/accounts - Liste des comptes')
    server.serve_forever()


if __name__ == '__main__':
    main()
