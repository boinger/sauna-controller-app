# Security Policy

## Network Security Model

This app is designed for **local network use only**:

- Communicates with the ESP32 controller via plain HTTP on your local WiFi
- No cloud service, no user accounts, no internet-facing connections
- No user data is collected, stored remotely, or transmitted off-network

The use of HTTP (not HTTPS) is a deliberate design choice — the app talks to an ESP32 microcontroller on your LAN that does not support TLS. If you need encrypted communication, consider placing the ESP32 behind a reverse proxy with TLS termination.

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

- **GitHub Security Advisory**: Use the [Security Advisories](https://github.com/boinger/sauna-controller-app/security/advisories) tab to report privately
- **Email**: Contact the maintainer via their GitHub profile

Please do **not** open a public issue for security vulnerabilities.

## Scope

Security reports are welcome for:

- Data leakage or unintended network communication
- Vulnerabilities in request construction or response handling
- Issues with local data storage

Out of scope:

- The intentional use of HTTP instead of HTTPS (see above)
- The intentional lack of authentication (the controller is a LAN appliance)
