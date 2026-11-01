#!/bin/bash

# Controlla se python3 è già installato
if command -v python3 &> /dev/null; then
    echo "Python è già installato."
else
    echo "Python3 non trovato. Ricerca del gestore di pacchetti in corso..."

    # Catena di controllo per le varie distribuzioni Linux
    if command -v apt-get &> /dev/null; then
        # Debian, Ubuntu, Linux Mint, Pop!_OS, ecc.
        echo "Rilevato gestore 'apt' (Debian/Ubuntu)..."
        sudo apt-get update && sudo apt-get install -y python3

    elif command -v dnf &> /dev/null; then
        # Fedora, RHEL 8+, Rocky Linux, AlmaLinux
        echo "Rilevato gestore 'dnf' (Fedora/RHEL/CentOS moderni)..."
        sudo dnf install -y python3

    elif command -v yum &> /dev/null; then
        # Versioni più vecchie di RHEL/CentOS
        echo "Rilevato gestore 'yum' (CentOS/RHEL legacy)..."
        sudo yum install -y python3

    elif command -v pacman &> /dev/null; then
        # Arch Linux, Manjaro, EndeavourOS
        echo "Rilevato gestore 'pacman' (Arch Linux)..."
        sudo pacman -Sy --noconfirm python

    elif command -v zypper &> /dev/null; then
        # openSUSE / SLES
        echo "Rilevato gestore 'zypper' (openSUSE)..."
        sudo zypper install -y python3

    elif command -v apk &> /dev/null; then
        # Alpine Linux
        echo "Rilevato gestore 'apk' (Alpine)..."
        sudo apk add --no-cache python3

    else
        echo "Errore: Nessun gestore di pacchetti supportato trovato. Installa Python manualmente."
        exit 1
    fi

    # Controllo finale post-installazione
    if command -v python3 &> /dev/null; then
        echo "Python3 è stato installato con successo!"
    else
        echo "Qualcosa è andato storto durante l'installazione."
        exit 1
    fi
fi

if [ ! -d ".venv" ]; then
    echo "creando il venv"
    python3 -m venv .venv
fi

source .venv/bin/activate

if [ -f "requirements.txt" ]; then
    echo "installando i requirements"
    pip install -r requirements.txt
    for i in {5..1}; do
        echo -ne "chiusura dello script tra $i...\r"
        sleep 1
    done
    exit 0
else
    echo "requirements.txt non esiste"
    echo "prova a riscaricare la repo"
    read -p "premi invio per chiudere questa finestra"
    exit 1
fi
