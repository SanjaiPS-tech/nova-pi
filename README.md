# Nova

Nova is a premium, powerful, and beautifully designed Flutter application built to manage, monitor, and interact with your personal server or Raspberry Pi directly from your mobile device.

The app acts as a centralized dashboard and remote controller, integrating various web services, SSH terminal access, and network diagnostics into one seamless experience.

![Nova App](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white) 

## ✨ Key Features

*   **Integrated Web Dashboards:** Easily manage services like Grafana, Webmin, Pi-Hole, and File Convertors through advanced built-in webviews.
*   **Fully Functional SSH Terminal:** Execute commands on your Raspberry Pi remotely using the fully featured, interactive xterm-based SSH terminal right on your device.
*   **Credential Manager:** Securely store and auto-fill complex unified passwords and logins for your various server services.
*   **Network Diagnostics:** Includes built-in utilities to perform latency tests and verify the connectivity of your dashboard, Pi-hole, Webmin, and SSH endpoints.
*   **Premium UI/UX:** A stunning dark mode design with glassmorphism effects, staggered grid layouts, and buttery smooth animations driven by `flutter_animate`.
*   **Offline/Fallback Detection:** Robust network state awareness handles disconnections and failovers between primary and backup URLs gracefully.

## 🛠️ Technology Stack

Nova is built with Flutter and leverages Several core packages:
*   `flutter_inappwebview` - For rendering full-featured web dashboards
*   `dartssh2` & `xterm` - Providing the raw power for the SSH Client and Terminal rendering
*   `provider` - State management
*   `shared_preferences` - Local storage for settings and saved credentials
*   `flutter_animate` - Powerful animation sequences and effects
*   `connectivity_plus` - Network state observation

## 🚀 Getting Started

To build and run this project, you need to have the Flutter SDK installed on your machine.

### Prerequisites

*   Flutter SDK (^3.10.4)
*   Android Studio / Xcode (depending on your target platform)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/SanjaiPS-tech/nova-pi.git
    cd nova_app
    ```

2.  **Get dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

## ⚙️ Configuration

Upon first launch, navigate to the **Settings** screen to configure your server details:
*   **Profile:** Set your username.
*   **Server IP:** The primary IP or hostname of your server (e.g., Raspberry Pi).
*   **Connectivity URLs:** Define primary and secondary fallback URLs for your dashboards (Grafana), Webmin, Pi-hole, etc.
*   **SSH Terminal Details:** By default, it looks for the host `nova`, user `rebel`. You can customize the Host, Port, Username, and Password for quick terminal access.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
