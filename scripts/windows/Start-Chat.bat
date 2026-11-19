@echo off
REM NETRAX demo chat window (Open WebUI) wired to the NETRAX gateway on this PC.
REM Every message goes through NETRAX at http://localhost:3000 - never straight to OpenAI or Ollama.
set IMAGE=ghcr.io/open-webui/open-webui:main
set TRIES=0
:pull
set /a TRIES+=1
echo Downloading the chat app (attempt %TRIES% of 5)...
docker pull %IMAGE%
if not errorlevel 1 goto pulled
if %TRIES% GEQ 5 (
  echo The download kept failing. Check your internet connection and run this again.
  pause
  exit /b 1
)
echo Download interrupted - retrying in 10 seconds. Finished parts are kept.
timeout /t 10 >nul
goto pull
:pulled
docker rm -f netrax-chat >nul 2>&1
docker run -d --name netrax-chat -p 3080:8080 ^
  --add-host=host.docker.internal:host-gateway ^
  -e OPENAI_API_BASE_URL=http://host.docker.internal:3000/openai/v1 ^
  -e ENABLE_OLLAMA_API=False ^
  -e OLLAMA_BASE_URL=http://ollama-disabled.invalid ^
  -e ENABLE_PERSISTENT_CONFIG=False ^
  -e WEBUI_NAME="NETRAX Chat" ^
  -v netrax-chat:/app/backend/data ^
  --restart unless-stopped ^
  %IMAGE%
if errorlevel 1 (
  echo Could not start the chat window. Is Docker Desktop running?
  pause
  exit /b 1
)
echo.
echo Starting NETRAX Chat. The first start downloads about 2-4 GB and can take several minutes.
echo Waiting for it to come up...
:wait
timeout /t 5 >nul
powershell -NoProfile -Command "try { Invoke-WebRequest http://localhost:3080 -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }"
if errorlevel 1 goto wait
start http://localhost:3080
echo NETRAX Chat is running at http://localhost:3080
pause
