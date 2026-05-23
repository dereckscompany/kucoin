#!/bin/bash

# R Package Lint Script
#
# Runs the formatter (air) and then lintr against the package, with the
# package loaded first so that `object_usage_linter` honours
# `utils::globalVariables()` declarations in R/zzz.R (data.table NSE
# columns etc.).
#
# Why load the package: `lintr::lint_package()` does NOT auto-load the
# package, so without `devtools::load_all()` it emits false-positive
# "no visible binding for global variable" warnings for every
# data.table column reference like `dt[, col := value]`.
#
# Format pass goes first so reformatted code is what gets linted; that
# also means a passing run leaves the working tree clean.

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

# ----- air format -----------------------------------------------------------

if ! command -v air >/dev/null 2>&1; then
  echo "[ERR] air is not installed."
  echo "  Install: curl -LsSf https://github.com/posit-dev/air/releases/latest/download/air-installer.sh | sh"
  exit 2
fi

echo "==> air format"
air format .
echo "[OK] air format complete."

# ----- lintr ----------------------------------------------------------------

echo ""
echo "==> lintr"
Rscript -e '
suppressMessages(devtools::load_all(quiet = TRUE))
l <- lintr::lint_package()
if (length(l) == 0L) {
  cat("\n[OK] lintr: 0 warnings.\n")
  quit(status = 0)
}
cat("\n[WARN] lintr:", length(l), "warning(s).\n\n")
print(l)
quit(status = 1)
'
