$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Production Build..."
# 1. Build Flutter for /admin/ subpath
flutter clean
flutter build web --base-href "/admin/"

# 2. Define Paths
$web = 'build\web'
$admin = 'build\web\admin'

# 3. Create Admin Directory
Write-Host "📂 Creating Admin Directory..."
New-Item -ItemType Directory -Force -Path $admin | Out-Null

# 4. Move Flutter Files to /admin
Write-Host "🚚 Moving Flutter Layout to /admin..."
Move-Item -Path "$web\flutter.js", "$web\flutter_bootstrap.js", "$web\index.html", "$web\main.dart.js", "$web\manifest.json", "$web\assets", "$web\canvaskit", "$web\icons", "$web\version.json" -Destination $admin -ErrorAction SilentlyContinue

# 5. Promote Sales Page to Root
Write-Host "🛒 Promoting Sales Page to Root..."
Copy-Item -Path "$web\salespage\*" -Destination $web -Recurse -Force
Move-Item -Path "$web\ventas.html" -Destination "$web\index.html" -Force

# 6. Deploy
Write-Host "🔥 Deploying to Firebase..."
firebase deploy

Write-Host "✅ DONE! Check https://digitalzonehn.web.app/"
