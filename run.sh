#!/bin/bash

# Spostati nella cartella in cui si trova lo script (funziona anche con doppio clic)
cd "$(dirname "$(readlink -f "$0")")" || exit 1

# Mostra un messaggio di errore, aspetta un invio e chiude
fallisci() {
    echo "Errore: $1"
    read -p "premi invio per chiudere questa finestra"
    exit 1
}

# Usa sudo solo se serve (se sei root o sudo non esiste, non lo usa)
if [ "$EUID" -eq 0 ]; then
    SUDO=""
elif command -v sudo &> /dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi

# Installa Python (con venv e pip) in base al gestore di pacchetti
installa_python() {
    if command -v apt-get &> /dev/null; then
        echo "Rilevato gestore 'apt' (Debian/Ubuntu)..."
        $SUDO apt-get update && $SUDO apt-get install -y python3 python3-venv python3-pip

    elif command -v dnf &> /dev/null; then
        echo "Rilevato gestore 'dnf' (Fedora/RHEL moderni)..."
        $SUDO dnf install -y python3 python3-pip

    elif command -v yum &> /dev/null; then
        echo "Rilevato gestore 'yum' (CentOS/RHEL legacy)..."
        $SUDO yum install -y python3 python3-pip

    elif command -v pacman &> /dev/null; then
        echo "Rilevato gestore 'pacman' (Arch Linux)..."
        $SUDO pacman -S --noconfirm python python-pip

    elif command -v zypper &> /dev/null; then
        echo "Rilevato gestore 'zypper' (openSUSE)..."
        $SUDO zypper install -y python3 python3-pip

    elif command -v apk &> /dev/null; then
        echo "Rilevato gestore 'apk' (Alpine)..."
        $SUDO apk add --no-cache python3 py3-pip

    else
        fallisci "nessun gestore di pacchetti supportato trovato. Installa Python manualmente."
    fi
}

# Controlla se python3 è già installato e se venv funziona
if command -v python3 &> /dev/null && python3 -c "import venv, ensurepip" &> /dev/null; then
    echo "Python (con venv) è già installato."
else
    echo "Python3 o il modulo venv non trovato. Ricerca del gestore di pacchetti in corso..."

    if [ -z "$SUDO" ] && [ "$EUID" -ne 0 ]; then
        fallisci "servono i permessi di root per installare Python, ma sudo non è disponibile."
    fi

    installa_python

    # Controllo finale post-installazione
    if command -v python3 &> /dev/null && python3 -c "import venv, ensurepip" &> /dev/null; then
        echo "Python3 è stato installato con successo!"
    else
        fallisci "qualcosa è andato storto durante l'installazione di Python."
    fi
fi

# Creazione del venv (se non esiste già o se è corrotto)
if [ ! -f ".venv/bin/activate" ]; then
    echo "creando il venv"
    rm -rf .venv
    python3 -m venv .venv || fallisci "impossibile creare il venv."
fi

# shellcheck disable=SC1091
source .venv/bin/activate || fallisci "impossibile attivare il venv."

if [ -f "requirements.txt" ]; then
    echo "installando i requirements"
    pip install -r requirements.txt || fallisci "installazione dei requisiti non riuscita."
else
    echo "requirements.txt non esiste"
    echo "prova a riscaricare la repo"
    read -p "premi invio per chiudere questa finestra"
    exit 1
fi

if [ ! -f "main.py" ]; then
    fallisci "main.py non trovato. Prova a riscaricare la repo."
fi

python3 main.py
status=$?

if [ $status -ne 0 ]; then
    echo "main.py è terminato con errore (codice $status)"
    read -p "premi invio per chiudere questa finestra"
    exit $status
fi

for i in {5..1}; do
    echo -ne "chiusura dello script tra $i...\r"
    sleep 1
done
echo
exit 0
