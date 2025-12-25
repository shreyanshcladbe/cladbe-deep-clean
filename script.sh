#!/usr/bin/env bash

set -e

# =========================================================
# Flags & Environment
# =========================================================
QUIET=false
VERBOSE=false
NO_COLOR=${NO_COLOR:-false}
CI_MODE=${CI:-false}

for arg in "$@"; do
  case "$arg" in
    -q|--quiet) QUIET=true ;;
    -v|--verbose) VERBOSE=true ;;
    --no-color) NO_COLOR=true ;;
  esac
done

# Verbose disables animations
if [[ "$VERBOSE" == "true" ]]; then
  QUIET=false
fi

# =========================================================
# Styling
# =========================================================
if [[ "$NO_COLOR" == "true" || "$CI_MODE" == "true" ]]; then
  RESET=""; BOLD=""; DIM=""
  RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""
else
  RESET="\033[0m"
  BOLD="\033[1m"
  DIM="\033[2m"
  RED="\033[31m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  BLUE="\033[34m"
  CYAN="\033[36m"
fi

# =========================================================
# Spinner (non-verbose only)
# =========================================================
SPINNER_FRAMES=("|" "/" "-" "\\")
spinner_pid=""

start_spinner() {
  [[ "$QUIET" == "true" || "$VERBOSE" == "true" ]] && return
  local msg="$1"
  (
    i=0
    while true; do
      printf "\r${CYAN}${SPINNER_FRAMES[i]}${RESET} ${DIM}%s${RESET}" "$msg"
      i=$(( (i + 1) % ${#SPINNER_FRAMES[@]} ))
      sleep 0.1
    done
  ) &
  spinner_pid=$!
}

stop_spinner() {
  [[ "$QUIET" == "true" || "$VERBOSE" == "true" ]] && return
  kill "$spinner_pid" >/dev/null 2>&1 || true
  wait "$spinner_pid" 2>/dev/null || true
  printf "\r${GREEN}[OK]${RESET} %s\n" "$1"
}

fail() {
  kill "$spinner_pid" >/dev/null 2>&1 || true
  printf "\r${RED}[FAIL]${RESET} %s\n" "$1"
  exit 1
}

# =========================================================
# Step Runner
# =========================================================
STEP=0

run_step() {
  STEP=$((STEP + 1))
  local description="$1"
  shift

  if [[ "$VERBOSE" == "true" ]]; then
    echo
    echo -e "${BOLD}STEP $STEP:${RESET} $description"
    echo "--------------------------------------------------"
    echo "Command:"
    echo "$*"
    echo "--------------------------------------------------"

    if "$@"; then
      echo "--------------------------------------------------"
      echo -e "${GREEN}[OK]${RESET} $description"
    else
      echo "--------------------------------------------------"
      echo -e "${RED}[FAIL]${RESET} $description"
      exit 1
    fi
    return
  fi

  start_spinner "$description"
  if "$@" >/dev/null 2>&1; then
    stop_spinner "$description"
  else
    fail "$description"
  fi
}

# =========================================================
# Locate Flutter project root
# =========================================================
echo -e "${BOLD}Locating Flutter project root...${RESET}"

CURRENT_DIR="$(pwd)"
PROJECT_ROOT=""

while [[ "$CURRENT_DIR" != "/" ]]; do
  if [[ -f "$CURRENT_DIR/pubspec.lock" || -f "$CURRENT_DIR/pubspec.yaml" ]]; then
    PROJECT_ROOT="$CURRENT_DIR"
    break
  fi
  CURRENT_DIR="$(dirname "$CURRENT_DIR")"
done

if [[ -z "$PROJECT_ROOT" ]]; then
  echo -e "${RED}[ERROR]${RESET} No Flutter project found."
  exit 1
fi

cd "$PROJECT_ROOT"
echo -e "${GREEN}[FOUND]${RESET} $PROJECT_ROOT"
echo

# =========================================================
# CocoaPods auto-install (macOS only)
# =========================================================
ensure_cocoapods() {
  if ! command -v pod >/dev/null 2>&1; then
    echo -e "${YELLOW}[INFO]${RESET} CocoaPods not found. Installing..."
    if command -v brew >/dev/null 2>&1; then
      brew install cocoapods
    else
      sudo gem install cocoapods
    fi
  fi
}

# =========================================================
# Cleanup pipeline
# =========================================================
echo -e "${BOLD}Starting Flutter deep clean...${RESET}"
echo

if [[ -f "pubspec.lock" ]]; then
  run_step "Removing pubspec.lock" rm -f pubspec.lock
else
  echo -e "${YELLOW}[SKIP]${RESET} pubspec.lock not found"
fi

run_step "flutter clean" flutter clean
run_step "dart pub cache clean" dart pub cache clean
run_step "flutter pub cache clean" flutter pub cache clean

if [[ -d "macos" ]]; then
  ensure_cocoapods
  run_step "pod deintegrate (macOS)" bash -c "cd macos && pod deintegrate"
fi
 
run_step "flutter pub get" flutter pub get

if [[ -d "macos" ]]; then
  run_step "pod install --repo-update (macOS)" bash -c "cd macos && pod install --repo-update"
fi

echo
echo -e "${GREEN}${BOLD}Flutter deep clean completed successfully.${RESET}"
