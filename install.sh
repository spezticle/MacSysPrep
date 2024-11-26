#!/bin/zsh
# This script is licensed under the PolyForm Noncommercial License 1.0.0.
# For more details, see the LICENSE file or visit https://polyformproject.org/licenses/noncommercial/1.0.0/

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

# Function to compare Python versions
function version_compare {
    python_version=$(python3 --version | awk '{print $2}')
    if [ "$(printf '%s\n%s' "$python_version" "$MIN_PYTHON_VERSION" | sort -V | head -n 1)" != "$MIN_PYTHON_VERSION" ]; then
        return 1  # Installed version is less than the minimum required
    fi
    return 0  # Installed version is equal to or greater than the minimum required
}

# Function to install Xcode Command Line Tools silently
function install_xcode {
    echo "Checking if Xcode Command Line Tools are installed..."
    if xcode-select -p >/dev/null 2>&1; then
        echo "Xcode Command Line Tools are already installed."
    else
        echo "Xcode Command Line Tools not found. Installing silently using softwareupdate..."

        # Install Xcode Command Line Tools silently
        sudo softwareupdate --install --agree-to-license --verbose "Command Line Tools for Xcode"

        # Verify installation
        if xcode-select -p >/dev/null 2>&1; then
            echo "Xcode Command Line Tools installed successfully."
        else
            echo -e "${BOLD_RED}Failed to install Xcode Command Line Tools. Exiting...${RESET}"
            exit 1
        fi
    fi
}

# Function to install Homebrew
function install_homebrew {
    echo "Checking if Homebrew is installed..."

    # Check known paths for Homebrew
    if [ -x "/opt/homebrew/bin/brew" ]; then
        export HOMEBREW_PATH="/opt/homebrew/bin/brew"
    elif [ -x "/usr/local/bin/brew" ]; then
        export HOMEBREW_PATH="/usr/local/bin/brew"
    fi

    # If Homebrew is found in a known location, test it
    if [ -n "$HOMEBREW_PATH" ]; then
        echo "Homebrew found at $HOMEBREW_PATH."
        if ! "$HOMEBREW_PATH" -v >/dev/null 2>&1; then
            echo "Homebrew is not functioning correctly. Reinstalling..."
            HOMEBREW_PATH=""
        fi
    fi

    # Install Homebrew if not found or not functioning
    if [ -z "$HOMEBREW_PATH" ]; then
        echo "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Verify installation location
        if [ -x "/opt/homebrew/bin/brew" ]; then
            HOMEBREW_PATH="/opt/homebrew/bin/brew"
        elif [ -x "/usr/local/bin/brew" ]; then
            HOMEBREW_PATH="/usr/local/bin/brew"
        else
            echo -e "${BOLD_RED}Homebrew installation failed. Exiting...${RESET}"
            exit 1
        fi
    fi

    echo "Homebrew installed successfully at $HOMEBREW_PATH."

    # Add Homebrew to PATH
    add_homebrew_to_path "$HOMEBREW_PATH"
}

# Function to add Homebrew to the PATH
function add_homebrew_to_path {
    local brew_prefix
    brew_prefix=$("$1" --prefix)
    local shell_name
    shell_name=$(basename "$SHELL")

    echo "Adding Homebrew to PATH for $shell_name..."

    # Determine the correct profile file to modify
    case $shell_name in
        zsh)
            profile_file="$HOME/.zprofile"
            ;;
        bash)
            profile_file="$HOME/.bash_profile"
            ;;
        *)
            profile_file="$HOME/.profile"
            ;;
    esac

    # Ensure the profile file exists
    touch "$profile_file"

    # Add Homebrew to PATH in the profile file if not already present
    if ! grep -q "$brew_prefix/bin" "$profile_file" >/dev/null 2>&1; then
        echo "export PATH=\"$brew_prefix/bin:\$PATH\"" >>"$profile_file"
        echo "Homebrew path added to $profile_file."
    else
        echo "Homebrew path already exists in $profile_file."
    fi

    # Update PATH for current session
    export PATH="$brew_prefix/bin:$PATH"
    echo "Homebrew path added to current session."
}

# Function to verify Python 3 dependencies
function check_python_dependencies {
    echo "Checking for Python 3 installation..."
    if ! command_exists python3; then
        echo "Python 3 not found."
        if [ "$HOME_BREW_INSTALLED" = true ]; then
            echo "Installing Python 3 via Homebrew..."
            brew install python3
        else
            echo -e "${BOLD_RED}Python 3 installation required. Please install manually.${RESET}"
            exit 1
        fi
    fi
    echo "Python 3 is installed: $(python3 --version)"

    # Check if Python version meets the minimum requirement
    echo "Checking Python version..."
    if ! version_compare; then
        echo "Python version is less than the required version ($MIN_PYTHON_VERSION). Updating via Homebrew..."
        brew reinstall python3
        if ! version_compare; then
            echo -e "${BOLD_RED}Failed to update Python to the required version. Exiting...${RESET}"
            exit 1
        fi
    fi
    echo "Python version is sufficient: $(python3 --version)"

    echo "Checking for venv module..."
    if ! python3 -m venv --help >/dev/null 2>&1; then
        echo "venv module is not available."
        if [ "$HOME_BREW_INSTALLED" = true ]; then
            echo "Reinstalling Python 3 via Homebrew..."
            brew reinstall python3
        else
            echo -e "${BOLD_RED}venv module installation required. Please resolve manually.${RESET}"
            exit 1
        fi
    fi
    echo "Python venv module is available."

    echo "Checking for pip..."
    if ! python3 -m pip --version >/dev/null 2>&1; then
        echo "pip not found. Installing pip..."
        python3 -m ensurepip --upgrade
        python3 -m pip install --upgrade pip
    fi
    echo "pip is installed: $(python3 -m pip --version)"
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
