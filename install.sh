#!/bin/zsh

# Configurable install path for Git repositories
GIT_INSTALL="/opt"

# Minimum required Python version
MIN_PYTHON_VERSION="3.9.0"

# Log file setup
LOG_FILE="$HOME/install-$(date +'%y%m%d-%H%M%S').log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Text formatting
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
RESET='\033[0m'

# Function to check if a command is available
function command_exists {
    command -v "$1" >/dev/null 2>&1
}

# Function to clean a directory
function clean_directory {
    local dir="$1"
    echo "Removing existing repository at $dir..."
    sudo rm -rvf "$dir" | tee -a "$LOG_FILE"
    echo "Existing repository at $dir has been removed."
}

# Function to install Git and clone a repository
function install_git_and_clone {
    echo "Checking for Git..."
    if ! command_exists git; then
        echo "Git is not installed."
        if [ "$HOME_BREW_INSTALLED" = true ]; then
            echo "Installing Git via Homebrew..."
            brew install git
        else
            echo -e "${BOLD_RED}Git installation required. Please install Git manually.${RESET}"
            exit 1
        fi
    fi
    echo "Git is installed: $(git --version)"

    # Parse repo details
    local repo_url="$1"
    local org_repo
    org_repo=$(echo "$repo_url" | sed -n 's#.*/\([^/]*\)/\([^/]*\)\.git$#\1/\2#p')
    local org=${org_repo%%/*}
    local repo=${org_repo##*/}

    if [ -z "$org" ] || [ -z "$repo" ]; then
        echo -e "${BOLD_RED}Invalid repository URL: $repo_url${RESET}"
        exit 1
    fi

    # Determine the install path
    local clone_path="$GIT_INSTALL/git/$org/$repo"

    # Check if the repository already exists
    if [ -d "$clone_path" ]; then
        if [ "$REINSTALL" = true ]; then
            clean_directory "$clone_path"
        else
            echo -e "${BOLD_RED}Repository already exists at $clone_path. Use --reinstall to clean and reinstall.${RESET}"
            exit 1
        fi
    fi

    # Clone the repository
    echo "Cloning repository: $repo_url to $clone_path..."
    sudo mkdir -p "$(dirname "$clone_path")"
    if ! sudo git clone "$repo_url" "$clone_path"; then
        echo -e "${BOLD_RED}Failed to clone the repository. Authentication or permissions error.${RESET}"
        exit 1
    fi
    echo "Repository cloned successfully."
}

# Main script logic
# Parse arguments
INSTALL_BREW=false
INSTALL_REPO=""
REINSTALL=false
for arg in "$@"; do
    case $arg in
        -brew)
            INSTALL_BREW=true
            ;;
        --install=*)
            INSTALL_REPO="${arg#--install=}"
            ;;
        --reinstall)
            REINSTALL=true
            ;;
        *)
            echo -e "${BOLD_RED}Unknown argument: $arg${RESET}"
            exit 1
            ;;
    esac
done

# Step 1: Install Xcode Command Line Tools
install_xcode

# Step 2: Optionally Install Homebrew
if [ "$INSTALL_BREW" = true ]; then
    install_homebrew
    export HOME_BREW_INSTALLED=true
else
    export HOME_BREW_INSTALLED=false
fi

# Step 3: Verify Python 3 and dependencies
check_python_dependencies

# Step 4: Clone repository if requested
if [ -n "$INSTALL_REPO" ]; then
    install_git_and_clone "$INSTALL_REPO"
fi

echo -e "${BOLD_GREEN}Installation complete. Logs can be found at: $LOG_FILE${RESET}"
