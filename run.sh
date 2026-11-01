#!/bin/bash

# moves to project dir
cd "$(dirname "$(readlink -f "$0")")" || exit 1

fallisci() {
    echo "Errore: $1"
    read -p "premi invio per chiudere questa finestra"
    exit 1
}

# uses sudo if needed
if [ "$EUID" -eq 0 ]; then
    SUDO=""
elif command -v sudo &> /dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi

# python install and venv setup (with compatibility with different distros)
installa_python() {
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
if command -v python3 &> /dev/null && python3 -c "import venv, ensurepip" &> /dev/null; then
    echo "Python (with venv) already installed."
else
    echo "Python3 or venv not found! Searching for package manager..."

    if [ -z "$SUDO" ] && [ "$EUID" -ne 0 ]; then
        fallisci "We need root access to install Python, but sudo is not available."
    fi

    installa_python

    # check
    if command -v python3 &> /dev/null && python3 -c "import venv, ensurepip" &> /dev/null; then
        echo "Python3 installed!"
    else
        fallisci "Something went wrong during the Python installation."
    fi
fi

# venv creation
if [ ! -f ".venv/bin/activate" ]; then
    echo "Creating venv..."
    rm -rf .venv
    python3 -m venv .venv || fallisci "Could not create venv."
fi

# shellcheck disable=SC1091
source .venv/bin/activate || fallisci "Could not activate venv."

if [ -f "requirements.txt" ]; then
    echo "Installing requirements..."
    pip install -r requirements.txt || fallisci "installazione dei requisiti non riuscita."
else
    echo "requirements.txt doesn't exist!"
    echo "Try to reinstall the repo or contact me at malpollus@gmail.com"
    read -p "press enter to close the window..."
    exit 1
fi

if [ ! -f "main.py" ]; then
    fallisci "main.py not found. Try to reinstall the repo or contact me at malpollus@gmail.com"
fi

python3 main.py
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
