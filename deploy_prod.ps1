$ErrorActionPreference = "Stop"

Write-Host "Starting Production Build..."
# 1. Build Flutter for /admin/ subpath
flutter clean
flutter build web --base-href "/Xk9m-523-Lp2z-Qr4v/"

# 2. Define Paths
$web = 'build\web'
$admin = 'build\web\Xk9m-523-Lp2z-Qr4v'

# 3. Create Admin Directory
Write-Host "Creating Admin Directory..."
New-Item -ItemType Directory -Force -Path $admin | Out-Null

# 4. Move Flutter Files to /admin
Write-Host "Moving Flutter Layout to /admin..."
Move-Item -Path "$web\flutter.js", "$web\flutter_bootstrap.js", "$web\index.html", "$web\main.dart.js", "$web\manifest.json", "$web\assets", "$web\canvaskit", "$web\icons", "$web\version.json", "$web\flutter_service_worker.js" -Destination $admin

# 5. Promote Sales Page to Root
Copy-Item -Path "web\salespage\*" -Destination $web -Recurse -Force
Copy-Item "web\robots.txt" -Destination $web -Force
Copy-Item "web\404.html" -Destination $web -Force
Move-Item -Path "$web\ventas.html" -Destination "$web\index.html" -Force

# 6. Deploy
Write-Host "Deploying to Firebase..."
firebase deploy

Write-Host "DONE! Check https://digitalzonehn.web.app/"
