# SysAdmin LearnApp - macOS Lernanwendung

Eine native macOS CLI- oder Menüleisten-Anwendung, die angehende Fachinformatiker für Systemintegration (FiSi) Schritt für Schritt durch Server-Setups, Datenbank-Konfigurationen und Netzwerkgrundlagen führt.

## Features & Lernpfade
- 🌐 **Webserver & Proxies:** Apache, Nginx, Reverse Proxies, SSL/TLS (Certbot).
- 💾 **Datenbanken:** MySQL/MariaDB, PostgreSQL (Installation, Users, Backups).
- 🛡️ **Netzwerk & Sicherheit:** SSH-Härtung, Firewalls (UFW/iptables), DNS (Bind9/dnsmasq).
- 🐋 **Virtualisierung:** Docker-Grundlagen, Container-Netzwerke, Docker Compose.

## Projekt-Struktur
- `main.swift`: Einstiegspunkt der Anwendung und CLI-Routing.
- `Components/`: UI-Elemente oder Terminal-Menüs.
- `Lessons/`: Strukturierte JSON- oder Swift-Dateien mit Lerninhalten, Aufgaben und Verifizierungs-Skripten.
- `Utils/`: Helfer für Systemprüfungen und Befehlsausführungen.

## Tech-Stack
- **Sprache:** Swift 6.x
- **Format:** macOS Command Line Tool (CLI) oder SwiftUI MenuBar App
- **Anforderungen:** macOS Sonoma (14.0) oder neuer
