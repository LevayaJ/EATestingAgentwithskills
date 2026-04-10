#!/bin/bash
# =============================================================
# TEST ORCHESTRATOR - Run Script
# Coordinates Backend → BDD → Playwright testing agents
# For: Employee Manager Application (EAEmployeeWithTestSprite)
# =============================================================

set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

REPORTS_DIR="./reports"
mkdir -p "$REPORTS_DIR/screenshots"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BACKEND_STATUS="skipped"
BDD_STATUS="skipped"
PLAYWRIGHT_STATUS="skipped"
BACKEND_EXIT=0
BDD_EXIT=0
PW_EXIT=0

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           TEST ORCHESTRATOR — Employee Manager             ║${NC}"
echo -e "${CYAN}║           Started: ${TIMESTAMP}              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ──────────────────────────────────────
# PRE-FLIGHT: Check if services are up
# ──────────────────────────────────────
echo -e "${BLUE}[PRE-FLIGHT] Checking if backend is running on :4000...${NC}"
if curl -s http://localhost:4000/employees > /dev/null 2>&1; then
  echo -e "${GREEN}  ✓ Backend is responsive${NC}"
else
  echo -e "${RED}  ✗ Backend is NOT responding on port 4000${NC}"
  echo -e "${YELLOW}  → Start backend: cd backend && npm start${NC}"
  echo -e "${YELLOW}  → Or use docker-compose: docker-compose up${NC}"
  exit 1
fi

echo -e "${BLUE}[PRE-FLIGHT] Checking if frontend is running on :5173...${NC}"
if curl -s http://localhost:5173 > /dev/null 2>&1; then
  echo -e "${GREEN}  ✓ Frontend is responsive${NC}"
else
  echo -e "${YELLOW}  ⚠ Frontend is NOT responding on port 5173${NC}"
  echo -e "${YELLOW}  → Playwright/BDD UI tests may fail${NC}"
  echo -e "${YELLOW}  → Start frontend: cd frontend && npm run dev${NC}"
fi

echo ""

# ──────────────────────────────────────
# PHASE 1: BACKEND AGENT
# ──────────────────────────────────────
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  PHASE 1: BACKEND TESTING AGENT${NC}"
echo -e "${CYAN}  Testing API endpoints at http://localhost:4000${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

START_TIME=$SECONDS

if [ -d "tests/backend" ]; then
  cd tests/backend
  npx jest --json --outputFile="../../${REPORTS_DIR}/backend-results.json" 2>&1 | tee "../../${REPORTS_DIR}/backend-console.log"
  BACKEND_EXIT=${PIPESTATUS[0]}
  cd ../..
else
  echo -e "${YELLOW}  ⚠ tests/backend directory not found — skipping${NC}"
  BACKEND_EXIT=0
fi

BACKEND_DURATION=$((SECONDS - START_TIME))

if [ $BACKEND_EXIT -eq 0 ]; then
  BACKEND_STATUS="passed"
  echo -e "${GREEN}  ✓ Backend tests PASSED (${BACKEND_DURATION}s)${NC}"
else
  BACKEND_STATUS="failed"
  echo -e "${RED}  ✗ Backend tests FAILED (${BACKEND_DURATION}s)${NC}"
  echo -e "${YELLOW}  ⚠ Proceeding to BDD tests with caution...${NC}"
fi

echo ""

# ──────────────────────────────────────
# PHASE 2: BDD AGENT
# ──────────────────────────────────────
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  PHASE 2: BDD TESTING AGENT${NC}"
echo -e "${CYAN}  Running Cucumber/Gherkin scenarios${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

START_TIME=$SECONDS

if [ -d "tests/bdd" ]; then
  cd tests/bdd
  npx cucumber-js --format json:"../../${REPORTS_DIR}/cucumber-results.json" 2>&1 | tee "../../${REPORTS_DIR}/bdd-console.log"
  BDD_EXIT=${PIPESTATUS[0]}
  cd ../..
else
  echo -e "${YELLOW}  ⚠ tests/bdd directory not found — skipping${NC}"
  BDD_EXIT=0
fi

BDD_DURATION=$((SECONDS - START_TIME))

if [ $BDD_EXIT -eq 0 ]; then
  BDD_STATUS="passed"
  echo -e "${GREEN}  ✓ BDD tests PASSED (${BDD_DURATION}s)${NC}"
else
  BDD_STATUS="failed"
  echo -e "${RED}  ✗ BDD tests FAILED (${BDD_DURATION}s)${NC}"
fi

echo ""

# ──────────────────────────────────────
# PHASE 3: PLAYWRIGHT AGENT
# ──────────────────────────────────────
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  PHASE 3: PLAYWRIGHT E2E TESTING AGENT${NC}"
echo -e "${CYAN}  Running full UI automation at http://localhost:5173${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

START_TIME=$SECONDS

if [ -d "tests/playwright" ]; then
  cd tests/playwright
  npx playwright test --reporter=json 2> "../../${REPORTS_DIR}/playwright-console.log" | tee "../../${REPORTS_DIR}/playwright-results.json"
  PW_EXIT=${PIPESTATUS[0]}
  cd ../..
else
  echo -e "${YELLOW}  ⚠ tests/playwright directory not found — skipping${NC}"
  PW_EXIT=0
fi

PW_DURATION=$((SECONDS - START_TIME))

if [ $PW_EXIT -eq 0 ]; then
  PLAYWRIGHT_STATUS="passed"
  echo -e "${GREEN}  ✓ Playwright tests PASSED (${PW_DURATION}s)${NC}"
else
  PLAYWRIGHT_STATUS="failed"
  echo -e "${RED}  ✗ Playwright tests FAILED (${PW_DURATION}s)${NC}"
fi

echo ""

# ──────────────────────────────────────
# PHASE 4: RESULT AGGREGATION
# ──────────────────────────────────────
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  PHASE 4: RESULT AGGREGATION${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TOTAL_DURATION=$((BACKEND_DURATION + BDD_DURATION + PW_DURATION))

# Create unified summary
cat > "${REPORTS_DIR}/orchestrator-summary.json" << EOF
{
  "orchestration_run": {
    "timestamp": "${TIMESTAMP}",
    "total_duration_seconds": ${TOTAL_DURATION},
    "overall_status": "$([ $BACKEND_EXIT -eq 0 ] && [ $BDD_EXIT -eq 0 ] && [ $PW_EXIT -eq 0 ] && echo 'passed' || echo 'failed')"
  },
  "agent_results": {
    "backend": {
      "status": "${BACKEND_STATUS}",
      "exit_code": ${BACKEND_EXIT},
      "duration_seconds": ${BACKEND_DURATION},
      "report_path": "${REPORTS_DIR}/backend-results.json"
    },
    "bdd": {
      "status": "${BDD_STATUS}",
      "exit_code": ${BDD_EXIT},
      "duration_seconds": ${BDD_DURATION},
      "report_path": "${REPORTS_DIR}/cucumber-results.json"
    },
    "playwright": {
      "status": "${PLAYWRIGHT_STATUS}",
      "exit_code": ${PW_EXIT},
      "duration_seconds": ${PW_DURATION},
      "report_path": "${REPORTS_DIR}/playwright-results.json"
    }
  }
}
EOF

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 ORCHESTRATION SUMMARY                      ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║  Agent         │ Status    │ Duration                      ║${NC}"
echo -e "${CYAN}║────────────────┼───────────┼───────────                    ║${NC}"

if [ $BACKEND_EXIT -eq 0 ]; then
  echo -e "${CYAN}║${NC}  Backend        │ ${GREEN}PASSED${NC}    │ ${BACKEND_DURATION}s"
else
  echo -e "${CYAN}║${NC}  Backend        │ ${RED}FAILED${NC}    │ ${BACKEND_DURATION}s"
fi

if [ $BDD_EXIT -eq 0 ]; then
  echo -e "${CYAN}║${NC}  BDD            │ ${GREEN}PASSED${NC}    │ ${BDD_DURATION}s"
else
  echo -e "${CYAN}║${NC}  BDD            │ ${RED}FAILED${NC}    │ ${BDD_DURATION}s"
fi

if [ $PW_EXIT -eq 0 ]; then
  echo -e "${CYAN}║${NC}  Playwright     │ ${GREEN}PASSED${NC}    │ ${PW_DURATION}s"
else
  echo -e "${CYAN}║${NC}  Playwright     │ ${RED}FAILED${NC}    │ ${PW_DURATION}s"
fi

echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  Total Duration: ${TOTAL_DURATION}s"
echo -e "${CYAN}║${NC}  Reports: ${REPORTS_DIR}/"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

# Exit with failure if any agent failed
if [ $BACKEND_EXIT -ne 0 ] || [ $BDD_EXIT -ne 0 ] || [ $PW_EXIT -ne 0 ]; then
  exit 1
fi

exit 0
