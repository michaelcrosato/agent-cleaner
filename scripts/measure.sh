#!/usr/bin/env sh
# measure.sh — measure a repository and detect its stack.
# Optional convenience used by Phase 1 of the protocol. An agent can run the
# equivalent commands directly. Read-only: this script changes nothing.
#
# Usage:  sh scripts/measure.sh [path]   (defaults to current directory)

set -eu
ROOT="${1:-.}"
cd "$ROOT"

say() { printf '%s\n' "$*"; }
hr()  { printf -- '-----------------------------------------------------------\n'; }
have() { command -v "$1" >/dev/null 2>&1; }

# Prefer git's view of tracked files; fall back to find.
list_files() {
  if have git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files
  else
    find . -type f \
      -not -path './.git/*' -not -path '*/node_modules/*' \
      -not -path '*/.venv/*' -not -path '*/dist/*' -not -path '*/build/*' \
      | sed 's|^\./||'
  fi
}

say "agent-cleaner :: repo measurement"
say "root: $(pwd)"
hr

FILES="$(list_files || true)"
FILE_COUNT="$(printf '%s\n' "$FILES" | grep -c . || true)"
say "Tracked files: ${FILE_COUNT}"

# Lines of code: tokei if available (accurate), else a wc-based estimate.
hr
if have tokei; then
  say "Lines of code (tokei):"
  tokei || true
else
  TOTAL_LOC="$(printf '%s\n' "$FILES" | while IFS= read -r f; do
      [ -f "$f" ] && wc -l <"$f" 2>/dev/null || true
    done | awk '{s+=$1} END{print s+0}')"
  say "Approx. lines of code (wc): ${TOTAL_LOC}    (install 'tokei' for a language breakdown)"
fi

hr
say "Largest tracked files:"
printf '%s\n' "$FILES" | while IFS= read -r f; do
    [ -f "$f" ] && printf '%s\t%s\n' "$(wc -c <"$f" 2>/dev/null || echo 0)" "$f"
  done | sort -rn | head -n 15 | awk '{printf "  %10d bytes  %s\n", $1, $2}'

hr
say "Detected manifests & lockfiles:"
for m in pyproject.toml setup.py setup.cfg requirements.txt uv.lock poetry.lock Pipfile \
         package.json package-lock.json pnpm-lock.yaml yarn.lock \
         go.mod go.sum Cargo.toml Cargo.lock Gemfile composer.json pom.xml build.gradle; do
  [ -e "$m" ] && say "  + $m"
done

hr
say "Detected tool configs:"
for c in .ruff.toml ruff.toml .pre-commit-config.yaml mypy.ini .mypy.ini \
         .eslintrc .eslintrc.json .eslintrc.js eslint.config.js .prettierrc \
         tsconfig.json .flake8 tox.ini; do
  [ -e "$c" ] && say "  + $c"
done
# Configs nested in pyproject
if [ -f pyproject.toml ]; then
  grep -q '\[tool.ruff' pyproject.toml 2>/dev/null && say "  + pyproject.toml [tool.ruff]"
  grep -q '\[tool.mypy' pyproject.toml 2>/dev/null && say "  + pyproject.toml [tool.mypy]"
  grep -q '\[tool.pytest' pyproject.toml 2>/dev/null && say "  + pyproject.toml [tool.pytest]"
fi

hr
say "Detected canonical command sources:"
[ -d .github/workflows ] && say "  + .github/workflows/ (CI)"
[ -e Makefile ] && say "  + Makefile"
[ -e justfile ] && say "  + justfile"
[ -e package.json ] && say "  + package.json scripts"

hr
say "Toolbelt availability (agent environment) — see TOOLBELT.md:"
check_tool() {  # check_tool <display-name> [alt-binaries...]
  for c in "$@"; do
    if have "$c"; then say "  [x] $1"; return; fi
  done
  say "  [ ] $1  (missing — install as repo dev-dep if a gate, else in agent env or request)"
}
check_tool rg                  # fast text search (retrieval funnel, layer 1)
check_tool ast-grep sg         # structural AST search/rewrite (layer 2)
check_tool fd fdfind           # fast file discovery
check_tool tokei               # LOC by language
check_tool ruff                # python lint+format gate
check_tool biome               # js/ts lint+format gate (fast default)
check_tool mypy                # python type gate
check_tool pytest              # python test gate
check_tool gitleaks trufflehog # secret scan gate

hr
say "Done. Use this to choose QUICK vs SCALE, find the repo's own gate commands, and decide"
say "which tools to use, install, or request (TOOLBELT.md)."
