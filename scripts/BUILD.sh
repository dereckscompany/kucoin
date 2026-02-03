#!/bin/bash

# R Package Build Script
# Supports building, checking, installing, and generating pkgdown documentation
# For CRAN submission: https://win-builder.r-project.org/upload.aspx

set -e  # Exit on any errors
set -u  # Exit on undefined variables

# ============================================================================
# Configuration
# ============================================================================

# Get package name from DESCRIPTION file (not directory name)
if [[ -f "DESCRIPTION" ]]; then
    PACKAGE_NAME=$(grep "^Package:" DESCRIPTION | sed 's/Package: *//')
else
    PACKAGE_NAME=$(basename "$PWD")
fi
SCRIPT_NAME=$(basename "$0")

# Colours for output
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m' # No Colour
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "${BOLD}${BLUE}==>${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# ============================================================================
# Help Function
# ============================================================================

show_help() {
    cat << EOF
${BOLD}USAGE:${NC}
    $SCRIPT_NAME [OPTIONS] [COMMAND]

${BOLD}DESCRIPTION:${NC}
    Build, check, install, and document R packages with ease.

${BOLD}COMMANDS:${NC}
    ${BOLD}all${NC}              Run full workflow: document → clean → build → check → install → readme → pkgdown
    ${BOLD}document${NC}         Generate package documentation (roxygen2)
    ${BOLD}clean${NC}            Remove previous build artifacts
    ${BOLD}build${NC}            Build the package tarball
    ${BOLD}check${NC}            Run R CMD check with --as-cran
    ${BOLD}install${NC}          Install the package locally
    ${BOLD}pkgdown${NC}          Build pkgdown website
    ${BOLD}pkgdown-preview${NC}  Build and preview pkgdown website
    ${BOLD}readme${NC}           Render README.Rmd to README.md
    ${BOLD}quick${NC}            Quick workflow: document → install (skip check)
    ${BOLD}help${NC}             Show this help message

${BOLD}FORMATTING:${NC}
    For code formatting, use scripts/FORMAT.sh instead.
    Run: ./scripts/FORMAT.sh --help

${BOLD}OPTIONS:${NC}
    ${BOLD}-h, --help${NC}       Show this help message
    ${BOLD}-n, --dry-run${NC}    Show what would be executed without running commands
    ${BOLD}-v, --verbose${NC}    Enable verbose output
    ${BOLD}--no-clean${NC}       Skip cleaning step in 'all' command
    ${BOLD}--no-manual${NC}      Skip manual/vignette building (faster checks)

${BOLD}EXAMPLES:${NC}
    # Full build and check workflow
    $SCRIPT_NAME all

    # Quick development iteration (no check)
    $SCRIPT_NAME quick

    # Just update documentation
    $SCRIPT_NAME document

    # Build and preview documentation website
    $SCRIPT_NAME pkgdown-preview

    # Dry run to see what would happen
    $SCRIPT_NAME --dry-run all

    # Check without building manual (faster)
    $SCRIPT_NAME --no-manual check

    # Render README
    $SCRIPT_NAME readme

${BOLD}NOTES:${NC}
    - Package name is auto-detected from current directory: ${BOLD}$PACKAGE_NAME${NC}
    - For CRAN submission, upload to: https://win-builder.r-project.org/upload.aspx
    - Requires: R, devtools, pkgdown (for documentation)

EOF
}

# ============================================================================
# Command Functions
# ============================================================================

run_cmd() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        print_info "[DRY RUN] $*"
    else
        if [[ "${VERBOSE:-0}" == "1" ]]; then
            print_info "Running: $*"
        fi
        "$@"
    fi
}

cmd_document() {
    print_header "Generating documentation..."
    run_cmd Rscript -e "devtools::document()"
    print_success "Documentation generated"
}

cmd_clean() {
    print_header "Cleaning previous builds..."
    if ls ${PACKAGE_NAME}_*.tar.gz 1> /dev/null 2>&1; then
        run_cmd rm -rf ${PACKAGE_NAME}_*.tar.gz
        print_success "Removed old tarballs"
    else
        print_info "No previous builds to clean"
    fi

    if [[ -d "${PACKAGE_NAME}.Rcheck" ]]; then
        run_cmd rm -rf ${PACKAGE_NAME}.Rcheck
        print_success "Removed check directory"
    fi
}

cmd_build() {
    print_header "Building package..."
    local build_opts=""
    if [[ "${NO_MANUAL:-0}" == "1" ]]; then
        build_opts="--no-manual --no-build-vignettes"
        print_info "Skipping manual and vignettes"
    fi
    run_cmd R CMD build $build_opts .
    print_success "Package built: ${PACKAGE_NAME}_*.tar.gz"
}

cmd_check() {
    print_header "Checking package with --as-cran..."
    local check_opts="--as-cran"
    if [[ "${NO_MANUAL:-0}" == "1" ]]; then
        check_opts="$check_opts --no-manual"
        print_info "Skipping manual checks"
    fi
    # Don't fail script on check errors (common without LaTeX)
    if run_cmd R CMD check $check_opts ${PACKAGE_NAME}_*.tar.gz; then
        print_success "Package check completed with no errors"
    else
        print_warning "Package check completed with warnings/errors (see log above)"
    fi
}

cmd_install() {
    print_header "Installing package..."
    run_cmd R CMD INSTALL ${PACKAGE_NAME}_*.tar.gz
    print_success "Package installed: $PACKAGE_NAME"
}

cmd_pkgdown() {
    print_header "Building pkgdown site..."
    run_cmd Rscript -e "pkgdown::build_site()"
    print_success "pkgdown site built in docs/"
}

cmd_pkgdown_preview() {
    print_header "Building and previewing pkgdown site..."
    run_cmd Rscript -e "pkgdown::build_site()"
    print_success "pkgdown site built"
    print_header "Opening preview..."
    run_cmd Rscript -e "pkgdown::preview_site()"
}

cmd_readme() {
    print_header "Rendering README.Rmd to README.md..."
    if [[ ! -f "README.Rmd" ]]; then
        print_error "README.Rmd not found"
        exit 1
    fi
    run_cmd Rscript -e "rmarkdown::render('README.Rmd', output_format = 'github_document')"
    print_success "README.md generated"
}

cmd_all() {
    print_header "Running full build workflow for: $PACKAGE_NAME"
    echo ""

    cmd_document
    echo ""

    if [[ "${NO_CLEAN:-0}" != "1" ]]; then
        cmd_clean
        echo ""
    fi

    cmd_build
    echo ""

    cmd_check
    echo ""

    cmd_install
    echo ""

    # Build README if README.Rmd exists
    if [[ -f "README.Rmd" ]]; then
        cmd_readme
        echo ""
    fi

    # Build pkgdown site
    cmd_pkgdown
    echo ""

    print_success "Full workflow complete!"
}

cmd_quick() {
    print_header "Running quick development workflow for: $PACKAGE_NAME"
    echo ""

    cmd_document
    echo ""

    cmd_install
    echo ""

    print_success "Quick workflow complete!"
    print_warning "Note: Package check was skipped. Run 'all' for full validation."
}

# ============================================================================
# Argument Parsing
# ============================================================================

DRY_RUN=0
VERBOSE=0
NO_CLEAN=0
NO_MANUAL=0
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help|help)
            show_help
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN=1
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        --no-clean)
            NO_CLEAN=1
            shift
            ;;
        --no-manual)
            NO_MANUAL=1
            shift
            ;;
        all|document|clean|build|check|install|pkgdown|pkgdown-preview|readme|quick)
            COMMAND=$1
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# ============================================================================
# Main Execution
# ============================================================================

# Default to 'all' if no command specified
if [[ -z "$COMMAND" ]]; then
    COMMAND="all"
fi

# Execute the command
case $COMMAND in
    all)
        cmd_all
        ;;
    document)
        cmd_document
        ;;
    clean)
        cmd_clean
        ;;
    build)
        cmd_build
        ;;
    check)
        cmd_check
        ;;
    install)
        cmd_install
        ;;
    pkgdown)
        cmd_pkgdown
        ;;
    pkgdown-preview)
        cmd_pkgdown_preview
        ;;
    readme)
        cmd_readme
        ;;
    quick)
        cmd_quick
        ;;
esac

exit 0
