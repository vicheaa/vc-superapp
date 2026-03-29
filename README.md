# Pyro Tyson - Super App MVP

Welcome to the **Pyro Tyson** Super App project! This Flutter application serves as a native shell that can seamlessly host and interact with multiple dynamically loaded web-based "mini-apps".

## 🏗 Architecture Overview

The Super App is built with a hybrid architecture:
1. **Core Shell (Flutter):** Handles native features, routing, device capabilities, authentication, and the overall navigation framework. 
2. **Mini-Apps (React/Vite):** Individual, modular web applications bundled into single HTML files and shipped alongside the Flutter app assets.
3. **The Javascript Bridge:** A robust communication layer that allows the Flutter Shell and the React Mini-Apps to pass data and trigger actions back and forth.

---

## 🚀 How It Works

### 1. Mini-App Storage & Bundling
Instead of hosting the mini-apps on a remote server (which requires a network connection to load initial UI) or running a single monolithic React app, **each mini-app is compiled independently**. 

The build pipeline for a mini-app (like the `Shop` app) uses **Vite** with `vite-plugin-singlefile`. This plugin takes all the CSS, logic, and assets of the React app and compiles it into a single, standalone `index.html` file. 

This standalone file is then output into the Flutter project's `assets/mini_apps/<app_id>/` directory:
```text
pyro-tyson/
├── lib/                             # Native Flutter Code
├── assets/
│   └── mini_apps/                   
│       ├── shop/                    # The "Shop" mini-app
│       │   └── index.html           # The compiled React app
│       └── <your_new_app>/          # Future mini-apps
└── mini_apps/                       # The Source Code for the React apps
    └── shop/
        ├── src/
        └── vite.config.js           # Configured to output to /assets/mini_apps/shop
```

### 2. The Flutter Router & WebView
When a user navigates to a mini-app (e.g., the Shop), the Flutter `AppRouter` parses the request and passes the `miniAppId` to the `SuperAppWebView`.

The `SuperAppWebView` automatically points a `WebViewWidget` to load the local asset file: `assets/mini_apps/${miniAppId}/index.html`. 

### 3. The Javascript Bridge
To make the web views feel native, we need to pass data (like user auth tokens or native actions) to the DOM.

**Flutter -> React:**
Flutter injects data by executing global javascript functions on the `window` object.
```dart
// Native side passing data to React
final jsCode = "window.receiveMessageFromNative('addToCart', $productJson);";
_controller.runJavaScript(jsCode);
```

**React -> Flutter:**
The web app communicates back to Flutter using a registered Javascript Channel named `SuperAppBridge`.
```javascript
// React side passing data to Native
const message = JSON.stringify({ action: 'checkoutClicked', data: { total: 100 } });
window.SuperAppBridge.postMessage(message);
```

---

## 🛠 How to add a new Mini-App

To create and integrate a new mini-app into the Super App, follow these steps:

### 1. Initialize the Mini-App
Inside the root of the Flutter project, create a new Vite app inside the `mini_apps/` source folder.
```bash
cd mini_apps
npm create vite@latest my_new_app -- --template react-ts
cd my_new_app
npm install 
npm install -D vite-plugin-singlefile
```

### 2. Configure Vite Build Output
Modify the new app's `vite.config.ts` (or `.js`) so that it bundles into a single file and deposits that file directly into the Flutter `assets/` directory.

```javascript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { viteSingleFile } from "vite-plugin-singlefile"

export default defineConfig({
  plugins: [react(), viteSingleFile()],
  build: {
    outDir: '../../assets/mini_apps/my_new_app',
    emptyOutDir: true,
  },
  base: './'
})
```

### 3. Build the App
Run your build command to generate the HTML file:
```bash
npm run build
```

### 4. Register the Asset in Flutter
Open the `pubspec.yaml` in the Flutter root and register your new asset directory:
```yaml
  assets:
    - assets/mini_apps/shop/
    - assets/mini_apps/my_new_app/  # <-- Add this line
```

### 5. Navigate to it!
In your Flutter code, you can now launch your new mini-app using the GoRouter:
```dart
context.push('/miniapp/my_new_app');
```
*Note: Make sure your `SuperAppWebView` and routing setup supports the `miniAppId` parameter correctly.*
