#!/bin/bash

# moves to project dir
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

fallisci() {
    echo "Errore: $1"
    read -p "premi invio per chiudere questa finestra"
    exit 1
}

# detects the OS
OS="$(uname -s)"
case "$OS" in
    Linux|Darwin) ;;
    MINGW*|MSYS*|CYGWIN*) fallisci "On Windows please use windows_run.bat instead." ;;
    *) fallisci "Unsupported operating system: $OS" ;;
esac

# uses sudo if needed
if [ "$EUID" -eq 0 ]; then
    SUDO=""
elif command -v sudo &> /dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi

# looks for a working Python (with venv + pip) and stores it in $PYTHON
PYTHON=""
trova_python() {
    local cmd
    PYTHON=""
    for cmd in python3 python; do
        if command -v "$cmd" &> /dev/null && "$cmd" -c "import venv, ensurepip" &> /dev/null; then
            PYTHON="$cmd"
            return 0
        fi
    done
    return 1
}

# python install on macOS (via Homebrew)
installa_mac() {
    local brew_path

    if ! command -v brew &> /dev/null; then
        # Homebrew is often installed but not in PATH in non-login shells
        for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            if [ -x "$brew_path" ]; then
                eval "$("$brew_path" shellenv)"
                break
            fi
        done
    fi

    if command -v brew &> /dev/null; then
        echo "Spotted 'brew' (Homebrew)..."
        brew install python
    else
        fallisci "Homebrew not found. Install Python from https://www.python.org/downloads/macos/ or Homebrew from https://brew.sh and run the script again."
    fi
}

# python install on Linux (with compatibility with different distros)
installa_linux() {
    if [ -z "$SUDO" ] && [ "$EUID" -ne 0 ]; then
        fallisci "We need root access to install Python, but sudo is not available."
    fi

    if command -v apt-get &> /dev/null; then
        echo "Spotted 'apt' (Debian/Ubuntu)..."
        $SUDO apt-get update && $SUDO apt-get install -y python3 python3-venv python3-pip

    elif command -v dnf &> /dev/null; then
        echo "Spotted 'dnf' (Fedora/RHEL moderni)..."
        $SUDO dnf install -y python3 python3-pip

    elif command -v yum &> /dev/null; then
        echo "Spotted 'yum' (CentOS/RHEL legacy)..."
        $SUDO yum install -y python3 python3-pip

    elif command -v pacman &> /dev/null; then
        echo "Spotted 'pacman' (Arch Linux)..."
        $SUDO pacman -S --noconfirm python python-pip

    elif command -v zypper &> /dev/null; then
        echo "Spotted 'zypper' (openSUSE)..."
        $SUDO zypper install -y python3 python3-pip

    elif command -v apk &> /dev/null; then
        echo "Spotted 'apk' (Alpine)..."
        $SUDO apk add --no-cache python3 py3-pip

    else
        fallisci "We couldn't spot a package manager, please install python manually."
    fi
}

# checks if python is installed and if the virtual enviroment works
if trova_python; then
    echo "Python (with venv) already installed."
else
    echo "Python or venv not found! Installing..."

    if [ "$OS" = "Darwin" ]; then
        installa_mac
    else
        installa_linux
    fi

    # check
    if trova_python; then
        echo "Python installed!"
    else
        fallisci "Something went wrong during the Python installation."
    fi
fi

# venv creation
if [ ! -f ".venv/bin/activate" ]; then
    echo "Creating venv..."
    rm -rf .venv
    "$PYTHON" -m venv .venv || fallisci "Could not create venv."
fi

# shellcheck disable=SC1091
source .venv/bin/activate || fallisci "Could not activate venv."

if [ -f "requirements.txt" ]; then
    echo "Installing requirements..."
    python -m pip install -r requirements.txt || fallisci "Could not install the requirements."
else
    echo "requirements.txt doesn't exist!"
    echo "Try to reinstall the repo or contact me at malpollus@gmail.com"
    read -p "press enter to close the window..."
    exit 1
fi

if [ ! -f "main.py" ]; then
    fallisci "main.py not found. Try to reinstall the repo or contact me at malpollus@gmail.com"
fi

python main.py
status=$?

if [ $status -ne 0 ]; then
    echo "main.py exited with error (code $status)"
    read -p "press enter to close the window..."
    exit $status
fi

for i in {5..1}; do
    echo -ne "closing window in $i...\r"
    sleep 1
done
echo
exit 0
