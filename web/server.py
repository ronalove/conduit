#!/usr/bin/env python3
"""
Backend proxy pour l'inscription Knights Network.
Proxie les requetes vers l'API Ergo sans exposer le token.
"""

import os
import json
import re
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

# Configuration
ERGO_API_URL = os.environ.get('ERGO_API_URL', 'http://ergo:8089')
ERGO_API_TOKEN = os.environ.get('ERGO_API_TOKEN', '')
PORT = int(os.environ.get('PORT', 8080))

class RegistrationHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory='.')

    def do_POST(self):
        if self.path == '/api/register':
            self.handle_registration()
        else:
            self.send_error(404, 'Not Found')

    def handle_registration(self):
        try:
            # Lire le body
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            data = json.loads(body.decode('utf-8'))

            # Validation
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

            # Appeler l'API Ergo
            ergo_response = self.call_ergo_api(account_name, password)

            if ergo_response['success']:
                self.send_json_response(200, {'message': 'Compte cree avec succes'})
            else:
                self.send_json_response(400, {'error': ergo_response['error']})

        except json.JSONDecodeError:
            self.send_json_response(400, {'error': 'JSON invalide'})
        except Exception as e:
            print(f'Error: {e}')
            self.send_json_response(500, {'error': 'Erreur interne du serveur'})

    def call_ergo_api(self, account_name, password):
        """Appelle l'API Ergo pour creer un compte."""
        url = f'{ERGO_API_URL}/v1/accounts'

        payload = json.dumps({
            'accountName': account_name,
            'password': password
        }).encode('utf-8')

        headers = {
            'Authorization': f'Bearer {ERGO_API_TOKEN}',
            'Content-Type': 'application/json'
        }

        try:
            req = Request(url, data=payload, headers=headers, method='POST')
            with urlopen(req, timeout=10) as response:
                return {'success': True}
        except HTTPError as e:
            error_body = e.read().decode('utf-8')
            try:
                error_data = json.loads(error_body)
                error_msg = error_data.get('error', 'Erreur inconnue')
            except:
                error_msg = f'Erreur {e.code}'

            # Traduire les erreurs courantes
            if 'already exists' in error_msg.lower() or 'account exists' in error_msg.lower():
                error_msg = 'Ce nom d\'utilisateur est deja pris'

            return {'success': False, 'error': error_msg}
        except URLError as e:
            return {'success': False, 'error': 'Impossible de contacter le serveur IRC'}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def send_json_response(self, status_code, data):
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()


def main():
    if not ERGO_API_TOKEN:
        print('ERREUR: ERGO_API_TOKEN non defini')
        exit(1)

    server = HTTPServer(('0.0.0.0', PORT), RegistrationHandler)
    print(f'Serveur d\'inscription demarre sur le port {PORT}')
    print(f'API Ergo: {ERGO_API_URL}')
    server.serve_forever()


if __name__ == '__main__':
    main()
