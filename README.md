# **Install Script**

This `install.sh` script is designed to streamline the installation of required dependencies, Python versions, Git repositories, and more, on macOS. It supports robust error handling, detailed logging, and flexible options for customizing behavior.

---

## **Features**
1. **Xcode Command Line Tools Installation**  
   Automatically installs Xcode Command Line Tools silently if they are not already present.

2. **Homebrew Installation**  
   Optionally installs Homebrew and ensures it is correctly configured in the system PATH.

3. **Python Dependency Management**  
   Ensures Python 3 is installed, meets the required version, and includes `pip` and `venv`. Automatically updates Python via Homebrew if necessary.

4. **Git Repository Management**  
   Clones public or private Git repositories to a specified base directory. Handles:
   - Existing repositories with an option to clean and reinstall.
   - Authentication errors for private repositories with clear error messages.

5. **Detailed Logging**  
   All operations are logged to a timestamped file in the user's home directory.

---

## **Variables**
You can configure the following variables at the top of the script:

| Variable           | Default Value          | Description                                                                                     |
|--------------------|------------------------|-------------------------------------------------------------------------------------------------|
| `GIT_INSTALL`      | `/opt`                | Base directory where Git repositories will be cloned.                                          |
| `MIN_PYTHON_VERSION` | `3.9.0`              | Minimum Python version required. Python will be updated via Homebrew if the installed version is lower. |
| `LOG_FILE`         | `$HOME/install-<timestamp>.log` | Path to the log file where all script operations and outputs are recorded.                     |

---

## **Options and Switches**

### **`-brew`**
- Installs Homebrew if it is not already installed.
- Ensures Homebrew's Python version is installed and configured as the default `python3`.
- Example:
  ```zsh
  ./install.sh -brew
  ```

---

### **`--install=<repository_url>`**
- Clones a Git repository to a directory based on the repository's organization and name.
- The destination directory will follow this structure:  
  `GIT_INSTALL/git/<organization>/<repository_name>`
- Example:
  ```zsh
  ./install.sh --install=https://github.com/spezticle/ShredSync.git
  ```
  This clones the repository to:
  `/opt/git/spezticle/ShredSync`

---

### **`--reinstall`**
- Used with `--install=<repository_url>`.  
- If the repository already exists at the destination path, this option removes the existing directory (`rm -rvf`) before cloning.
- Logs the deleted files and directory cleanup process.
- Example:
  ```zsh
  ./install.sh --install=https://github.com/spezticle/ShredSync.git --reinstall
  ```

---

### **Combining Options**
You can combine options to run multiple tasks in a single execution.  
Example:
```zsh
./install.sh -brew --install=https://github.com/spezticle/ShredSync.git --reinstall
```

This:
1. Installs Homebrew if needed.
2. Cleans and reinstalls the specified repository.

---

## **Usage Examples**

### **Basic Python and Dependency Check**
```zsh
./install.sh
```
- Ensures Xcode Command Line Tools and Python 3 are installed.
- Verifies that Python meets the minimum required version.

---

### **Install Homebrew and Python**
```zsh
./install.sh -brew
```
- Installs Homebrew if not present.
- Ensures Python 3 meets the required version.

---

### **Clone a Git Repository**
```zsh
./install.sh --install=https://github.com/spezticle/ShredSync.git
```
- Clones the repository to `/opt/git/spezticle/ShredSync`.

---

### **Reinstall a Git Repository**
```zsh
./install.sh --install=https://github.com/spezticle/ShredSync.git --reinstall
```
- Removes the existing repository if it already exists.
- Clones the repository to `/opt/git/spezticle/ShredSync`.

---

### **Install Everything**
```zsh
./install.sh -brew --install=https://github.com/spezticle/ShredSync.git --reinstall
```
- Installs Homebrew.
- Ensures Python 3 meets the minimum version.
- Removes and reinstalls the repository.

---

## **Error Handling**

### **Authentication Errors**
- If a private repository cannot be cloned due to authentication issues, the script exits with:
  ```plaintext
  Failed to clone the repository. Authentication or permissions error.
  ```
  Ensure you have configured Git authentication properly (e.g., SSH keys or a GitHub Personal Access Token).

---

### **Repository Already Exists**
- If the destination path already exists and `--reinstall` is not provided, the script exits with:
  ```plaintext
  Repository already exists at <path>. Use --reinstall to clean and reinstall.
  ```

---

## **Logging**
- All operations, including errors and output, are logged to a file in the user's home directory.
- The log file path is displayed at the end of the script:
  ```plaintext
  Installation complete. Logs can be found at: /Users/<username>/install-231127-143215.log
  ```

---

## **Notes**
1. The script assumes macOS and requires `zsh` as the shell.
2. For private repositories, ensure Git authentication (SSH or token) is configured before running the script.
3. Running the script may require `sudo` for certain operations (e.g., removing directories in `/opt`).

---
