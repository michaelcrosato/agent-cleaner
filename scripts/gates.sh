#!/usr/bin/env sh
# gates.sh — run the detected quality gates for a repository.
# Optional convenience used by Phases 4-5 of the protocol. Prefer the repo's
# own canonical commands (CI / Makefile / package scripts) when they exist.
#
# Usage:
#   sh scripts/gates.sh          # check mode (non-mutating) — safe to run anywhere
#   sh scripts/gates.sh --fix    # apply safe fixes (format + lint --fix)
#
# Gracefully skips any gate whose tool or config is absent. Exit status is
# non-zero if any *run* gate fails, so CI can use it too.

set -u
FIX=0
[ "${1:-}" = "--fix" ] && FIX=1

have() { command -v "$1" >/dev/null 2>&1; }
say()  { printf '%s\n' "$*"; }
hr()   { printf -- '-----------------------------------------------------------\n'; }

STATUS=0
run() {  # run <label> <cmd...>
  label="$1"; shift
  say ">> ${label}: $*"
  if "$@"; then say "   PASS"; else say "   FAIL"; STATUS=1; fi
}

say "agent-cleaner :: quality gates  (mode: $( [ $FIX -eq 1 ] && echo FIX || echo CHECK ))"
hr

# ---------- Python ----------
if [ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ]; then
  say "[python]"
  if have ruff; then
    if [ $FIX -eq 1 ]; then
      run "ruff lint (fix)"   ruff check --fix .
      run "ruff format"       ruff format .
    else
      run "ruff lint"         ruff check .
      run "ruff format check" ruff format --check .
    fi
  else
    say "   (ruff not installed — skipped)"
  fi

  if have mypy && { [ -f mypy.ini ] || [ -f .mypy.ini ] || grep -q '\[tool.mypy' pyproject.toml 2>/dev/null; }; then
    run "mypy" mypy .
  elif have ty && grep -q '\[tool.ty' pyproject.toml 2>/dev/null; then
    run "ty" ty check
  else
    say "   (no configured type checker — skipped)"
  fi

  if have pytest; then
    run "pytest" pytest -q
  else
    say "   (pytest not installed — skipped)"
  fi
  hr
fi

# ---------- JS / TS ----------
if [ -f package.json ]; then
  say "[node]"
  PM="npm"; have pnpm && [ -f pnpm-lock.yaml ] && PM="pnpm"; have yarn && [ -f yarn.lock ] && PM="yarn"

  # Prefer Biome when the repo is configured for it; otherwise Prettier + ESLint.
  if [ -f biome.json ] || [ -f biome.jsonc ] || grep -q '@biomejs/biome' package.json 2>/dev/null; then
    BIOME="biome"; have biome || { have npx && BIOME="npx --no-install @biomejs/biome"; }
    if [ $FIX -eq 1 ]; then run "biome check (write)" $BIOME check --write .
    else run "biome check" $BIOME check .; fi
  elif have npx; then
    if grep -q '"prettier"' package.json 2>/dev/null || [ -f .prettierrc ]; then
      if [ $FIX -eq 1 ]; then run "prettier (write)" npx --no-install prettier --write .
      else run "prettier check" npx --no-install prettier --check .; fi
    fi
    if grep -q '"eslint"' package.json 2>/dev/null || [ -f .eslintrc ] || [ -f eslint.config.js ]; then
      if [ $FIX -eq 1 ]; then run "eslint (fix)" npx --no-install eslint . --fix
      else run "eslint" npx --no-install eslint .; fi
    fi
  fi

  if [ -f tsconfig.json ] && have npx; then
    run "tsc --noEmit" npx --no-install tsc --noEmit
  fi

  if grep -q '"test"' package.json 2>/dev/null; then
    run "tests" "$PM" test
  else
    say "   (no test script — skipped)"
  fi
  hr
fi

# ---------- Go ----------
if [ -f go.mod ]; then
  say "[go]"
  have gofmt && { [ $FIX -eq 1 ] && run "gofmt -w" gofmt -w . || run "gofmt -l" sh -c 'test -z "$(gofmt -l .)"'; }
  have go && run "go vet"  go vet ./...
  have go && run "go test" go test ./...
  hr
fi

# ---------- Secret scan (best effort) ----------
say "[secrets]"
if have trufflehog; then run "trufflehog" trufflehog filesystem . --no-update
elif have gitleaks; then run "gitleaks" gitleaks detect --no-banner
else say "   (no secret scanner installed — install gitleaks or trufflehog; skipped)"; fi
hr

say "Overall: $( [ $STATUS -eq 0 ] && echo PASS || echo FAIL )"
exit $STATUS
