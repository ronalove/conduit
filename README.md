<p align="center">
  <img src="assets/app_icon.png" alt="Knights Network" width="128">
</p>

<h1 align="center">Knights Network</h1>

<p align="center">
  Client IRC moderne et securise pour le reseau Knights
</p>

<p align="center">
  <a href="https://github.com/r9r-dev/conduit/releases/latest">
    <img src="https://img.shields.io/github/v/release/r9r-dev/conduit?style=flat-square&color=blue" alt="Derniere release">
  </a>
  <a href="https://github.com/r9r-dev/conduit/actions/workflows/release.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/r9r-dev/conduit/release.yml?style=flat-square&label=build" alt="Statut CI">
  </a>
  <a href="https://github.com/r9r-dev/conduit/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/r9r-dev/conduit?style=flat-square" alt="Licence">
  </a>
  <a href="https://github.com/r9r-dev/conduit/releases">
    <img src="https://img.shields.io/github/downloads/r9r-dev/conduit/total?style=flat-square&color=green" alt="Telechargements">
  </a>
</p>

<p align="center">
  <a href="#installation">Installation</a> •
  <a href="#fonctionnalites">Fonctionnalites</a> •
  <a href="#developpement">Developpement</a> •
  <a href="docs/USER_MANUAL.md">Documentation</a>
</p>

&nbsp;

<p align="center">
  <img src="assets/banner.png" alt="Knights Network Preview" width="500">
</p>

&nbsp;

## A propos

Knights Network est un client IRCv3 multi-plateforme developpe avec Flutter. Il est concu specifiquement pour le serveur Knights et offre une experience de chat moderne avec support complet des specifications IRCv3.

**Caracteristiques principales :**

- Interface moderne et reactive
- Authentification securisee via SASL
- Historique des messages persistant
- Indicateurs de frappe en temps reel
- Support multi-plateforme natif

&nbsp;

## Installation

Telechargez la derniere version pour votre plateforme :

| Plateforme | Telechargement | Instructions |
|------------|----------------|--------------|
| **Android** | [APK](https://github.com/r9r-dev/conduit/releases/latest) | Activer "Sources inconnues" dans les parametres |
| **macOS** | [DMG](https://github.com/r9r-dev/conduit/releases/latest) | Clic-droit > Ouvrir (application non signee) |
| **Windows** | [ZIP](https://github.com/r9r-dev/conduit/releases/latest) | Extraire et lancer l'executable |
| **Linux** | [AppImage](https://github.com/r9r-dev/conduit/releases/latest) | `chmod +x` puis executer |

> **iOS** : Disponible prochainement via TestFlight

&nbsp;

## Fonctionnalites

### Specifications IRCv3 supportees

<details>
<summary><strong>Core</strong></summary>

- CAP 302 - Negociation de capacites amelioree
- cap-notify - Notification de changement de capacites
- SASL v3.2 - Authentification PLAIN
- message-tags - Support complet des tags
- msgid - Identifiant de message
- server-time - Horodatage serveur
- echo-message - Echo des messages
- labeled-response - Correlation requete/reponse
- standard-replies - Format de reponse standard
- multi-prefix - Modes utilisateur multiples
- UTF8ONLY - Encodage UTF-8

</details>

<details>
<summary><strong>Presence et utilisateurs</strong></summary>

- away-notify - Notification de statut absent
- account-notify - Notification de changement de compte
- account-tag - Tag de compte sur les messages
- chghost - Notification de changement d'hote
- setname - Changement de nom reel
- extended-join - Informations JOIN etendues
- invite-notify - Notification d'invitation
- Monitor - Surveillance de presence
- WHOX - Requete WHO etendue

</details>

<details>
<summary><strong>Batch et historique</strong></summary>

- batch - Groupement de messages
- multiline - Messages multi-lignes
- chathistory - Recuperation d'historique
- read-marker - Suivi de position de lecture

</details>

<details>
<summary><strong>Interactif</strong></summary>

- +typing - Indicateur de frappe
- reply - Reference de reponse
- channel-context - Contexte de canal pour DMs

</details>

<details>
<summary><strong>Securite</strong></summary>

- sts - Strict Transport Security
- Connexion TLS obligatoire
- SASL over TLS

</details>

&nbsp;

## Developpement

### Prerequis

- Flutter 3.38+
- Dart 3.10+

### Demarrage rapide

```bash
# Cloner le repository
git clone https://github.com/r9r-dev/conduit.git
cd conduit

# Installer les dependances
flutter pub get

# Generer le code (modeles, providers)
flutter pub run build_runner build

# Lancer l'application
flutter run -d macos  # ou windows, linux, ios, android
```

### Commandes utiles

```bash
# Mode watch pour la generation de code
flutter pub run build_runner watch

# Tests unitaires
flutter test

# Analyse statique
flutter analyze
```

&nbsp;

## Contribuer

Les contributions sont les bienvenues ! Consultez les [issues ouvertes](https://github.com/r9r-dev/conduit/issues) pour voir les taches en cours.

&nbsp;

## Documentation

- [Manuel utilisateur](docs/USER_MANUAL.md)
- [Roadmap](https://github.com/r9r-dev/conduit/milestones)

### References IRCv3

- [IRCv3 Specifications](https://ircv3.net/irc/)
- [Modern IRC Documentation](https://modern.ircdocs.horse)

&nbsp;

## Licence

MIT - Voir le fichier [LICENSE](LICENSE) pour plus de details.

&nbsp;

<p align="center">
  <sub>Fait avec Flutter</sub>
</p>
