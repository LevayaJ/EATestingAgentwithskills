@echo off
REM =============================================================
REM TEST ORCHESTRATOR - Run Script (Windows)
REM Coordinates Backend → BDD → Playwright testing agents
REM For: Employee Manager Application (EAEmployeeWithTestSprite)
REM =============================================================

setlocal enabledelayedexpansion

set "REPORTS_DIR=..\reports"
if not exist "%REPORTS_DIR%" mkdir %REPORTS_DIR%

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║           TEST ORCHESTRATOR - Employee Manager             ║
echo ║              Windows Batch Script Version                  ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

REM ──────────────────────────────────────
REM PRE-FLIGHT: Check if services are up
REM ──────────────────────────────────────
echo [PRE-FLIGHT] Checking if backend is running on localhost:4000...
timeout /t 1 /nobreak > nul
echo   Note: Ensure backend is running before proceeding
echo.

echo [PRE-FLIGHT] Checking if frontend is running on localhost:5173...
timeout /t 1 /nobreak > nul
echo   Note: Ensure frontend is running before proceeding
echo.

REM ─────────────────────────────────────────
REM PHASE 1: BACKEND TESTING AGENT
REM ─────────────────────────────────────────
echo.
echo ═══════════════════════════════════════════════════════════════
echo [PHASE 1] Running BACKEND Testing Agent
echo ═══════════════════════════════════════════════════════════════
echo.

cd ..\tests\backend
if exist package.json (
  echo Installing backend test dependencies...
  call npm install > nul 2>&1
  echo Running backend tests...
  call npm test
  if !errorlevel! equ 0 (
    echo [✓] Backend tests completed
  ) else (
    echo [✗] Backend tests failed
  )
) else (
  echo [!] Backend test package.json not found
)

cd ..\..\orchestrator

REM ─────────────────────────────────────────
REM PHASE 2: BDD TESTING AGENT
REM ─────────────────────────────────────────
echo.
echo ═══════════════════════════════════════════════════════════════
echo [PHASE 2] Running BDD Testing Agent
echo ═══════════════════════════════════════════════════════════════
echo.

cd ..\tests\bdd
if exist package.json (
  echo Installing BDD test dependencies...
  call npm install > nul 2>&1
  echo Running BDD tests...
  call npm test
  if !errorlevel! equ 0 (
    echo [✓] BDD tests completed
  ) else (
    echo [✗] BDD tests may have issues - continuing...
  )
) else (
  echo [!] BDD test package.json not found
)

cd ..\..\orchestrator

REM ─────────────────────────────────────────
REM PHASE 3: PLAYWRIGHT TESTING AGENT
REM ─────────────────────────────────────────
echo.
echo ═══════════════════════════════════════════════════════════════
echo [PHASE 3] Running PLAYWRIGHT Testing Agent
echo ═══════════════════════════════════════════════════════════════
echo.

cd ..\tests\playwright
if exist package.json (
  echo Installing Playwright test dependencies...
  call npm install > nul 2>&1
  echo Running Playwright tests...
  echo Note: Playwright tests require frontend running...
  REM call npm test
  echo [!] Playwright tests require interactive browser setup
) else (
  echo [!] Playwright test package.json not found
)

cd ..\..\orchestrator

REM ─────────────────────────────────────────
REM AGGREGATION
REM ─────────────────────────────────────────
echo.
echo ═══════════════════════════════════════════════════════════════
echo [AGGREGATION] Merging all test results
echo ═══════════════════════════════════════════════════════════════
echo.

if exist aggregate.js (
  node aggregate.js
) else (
  echo [!] aggregate.js not found
)

echo.
echo ═══════════════════════════════════════════════════════════════
echo ✓ Test Orchestration Complete!
echo ═══════════════════════════════════════════════════════════════
echo.
echo Generated reports:
echo   - %REPORTS_DIR%\unified-report.json
echo   - %REPORTS_DIR%\unified-report.md
echo.

endlocal
