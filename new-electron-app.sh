#!/usr/bin/env bash

APP_NAME="$1"
ELECTRON_VERSION="37.10.0"

if [ -z "$APP_NAME" ]; then
  echo "Användning: new-electron-app <app-namn>"
  exit 1
fi

mkdir "$APP_NAME"
cd "$APP_NAME" || exit

npm init -y

npm install --save-dev typescript ts-node @types/node
npm install --save-dev electron@$ELECTRON_VERSION

npx tsc --init

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "moduleResolution": "node",
    "skipLibCheck": true
  }
}
EOF

mkdir src

cat > src/main.ts << 'EOF'
import { app, BrowserWindow } from "electron";

function createWindow() {
  const win = new BrowserWindow({
    width: 800,
    height: 600,
  });

  win.loadFile("index.html");
}

app.whenReady().then(createWindow);

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
EOF

cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
  <body>
    <h1>Hello from Electron + TypeScript!</h1>
  </body>
</html>
EOF

npx json -I -f package.json -e '
this.main = "dist/main.js";
this.scripts = {
  build: "tsc",
  start: "npm run build && electron ."
}
'

echo "Klar. Kör: cd $APP_NAME && npm start"
