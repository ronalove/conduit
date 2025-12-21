# Page d'inscription Knights Network

Page web permettant aux utilisateurs de creer un compte sur le serveur IRC.

## Architecture

```
[Navigateur] -> [Page HTML] -> [Backend Python] -> [API Ergo]
                                     |
                              (Token API via env)
```

## Deploiement

### 1. Creer un fichier `.env`

```bash
# Sur le serveur, dans le dossier de deploiement
ERGO_API_TOKEN=votre_token_api_ergo
ERGO_API_URL=http://ergo:8089
```

### 2. Lancer avec Docker Compose

```bash
docker-compose up -d
```

L'image est automatiquement buildee et pushee sur `ghcr.io/r9r-dev/knights-registration:latest` via GitHub Actions.

### 3. Configurer le reseau

Modifiez `docker-compose.yml` pour utiliser le bon reseau Docker (celui ou tourne Ergo).

## Variables d'environnement

| Variable | Description | Defaut |
|----------|-------------|--------|
| `ERGO_API_TOKEN` | Token d'authentification API Ergo | (requis) |
| `ERGO_API_URL` | URL de l'API Ergo | `http://ergo:8089` |
| `PORT` | Port d'ecoute | `8080` |

## Build manuel (optionnel)

```bash
cd web
docker build -t knights-registration .
```

## Securite

- Le token API est passe via variable d'environnement (jamais dans le code)
- Validation des entrees utilisateur cote serveur
- Le proxy/tunnel gere l'authentification et TLS
