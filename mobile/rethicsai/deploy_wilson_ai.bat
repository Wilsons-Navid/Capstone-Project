@echo off
echo ========================================
echo Wilson AI Enhanced Model Deployment
echo ========================================
echo.

echo Checking Firebase login status...
firebase projects:list
if errorlevel 1 (
    echo Please log in to Firebase first:
    echo firebase login
    pause
    exit /b 1
)

echo.
echo Current project:
firebase use --add
if errorlevel 1 (
    echo Please select your Firebase project
    pause
    exit /b 1
)

echo.
echo Building Cloud Functions...
cd functions
call npm install
if errorlevel 1 (
    echo Failed to install dependencies
    pause
    exit /b 1
)

call npm run build
if errorlevel 1 (
    echo Failed to build functions
    pause
    exit /b 1
)

cd ..

echo.
echo Deploying Wilson AI Enhanced Functions...
firebase deploy --only functions:wilsonAIVertex,functions:getAfricanThreatIntelligence,functions:generateSecurityTraining
if errorlevel 1 (
    echo Deployment failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Wilson AI Enhanced Model Deployed Successfully!
echo ========================================
echo.
echo Available Functions:
echo - wilsonAIVertex: Enhanced AI chat with Gemini
echo - getAfricanThreatIntelligence: Real-time threat data
echo - generateSecurityTraining: Custom training content
echo.
echo Next steps:
echo 1. Update your client app to use Vertex AI features
echo 2. Monitor usage in Firebase Console
echo 3. Set up billing alerts in Google Cloud Console
echo.
pause