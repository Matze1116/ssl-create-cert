#!/bin/bash

# Funktion zum sicheren Generieren eines zufälligen Passworts mit mindestens 32 Zeichen (alphanumerisch)
generate_password() {
    echo "$(openssl rand -base64 32)"
}

# Stelle sicher, dass das Verzeichnis 'certs' existiert
cert_base_dir=~/certs
if [ ! -d "$cert_base_dir" ]; then
    echo "Das Verzeichnis 'certs' existiert nicht. Erstelle das Verzeichnis..."
    mkdir -p "$cert_base_dir" || { echo "Fehler beim Erstellen des Verzeichnisses"; exit 1; }
    echo "'certs'-Verzeichnis erstellt."
fi

# Wechsle in das 'certs'-Verzeichnis
cd "$cert_base_dir" || { echo "Fehler beim Wechseln in das Verzeichnis"; exit 1; }

# Prüfe, ob bereits Konfigurationsdaten und das Passwort existieren
config_file="$cert_base_dir/openssl_data.conf"
password_file="$cert_base_dir/cpearst"

if [ -f "$config_file" ] && [ -f "$password_file" ]; then
    echo "Verwende gespeicherte OpenSSL-Daten und Passwort."
    source "$config_file"
    ca_password=$(cat "$password_file")
else
    # Frage den Benutzer, ob er ein sicheres Passwort automatisch generieren lassen möchte
    read -p "Möchtest du ein sicheres Passwort automatisch generieren lassen? (y/n): " generate_pass
    if [ "$generate_pass" == "y" ]; then
        ca_password=$(generate_password)
        echo "Automatisch generiertes Passwort: $ca_password"
        echo "Das Passwort wird in der Datei 'cpearst' im Ordner 'certs' gespeichert."
        echo "$ca_password" > "$password_file"
        echo "Bitte notiere dieses Passwort sicher und lösche die Datei 'cpearst', sobald du es nicht mehr benötigst."
    else
        read -sp "Bitte gib ein Passwort für myCA.key ein: " ca_password
        echo
        read -p "Möchtest du das Passwort im 'certs'-Ordner speichern? (y/n): " save_pass
        if [ "$save_pass" == "y" ]; then
            echo "$ca_password" > "$password_file"
            echo "Das Passwort wurde in der Datei 'cpearst' im Ordner 'certs' gespeichert. Bitte lösche diese Datei, sobald du das Passwort nicht mehr benötigst."
        else
            echo "Bitte notiere das Passwort sicher."
        fi
    fi

    # Frage nach den OpenSSL-Konfigurationsdaten
    read -p "Bitte gib dein Landeskürzel (z.B. AT) ein: " country
    read -p "Bitte gib dein Bundesland (z.B. Vorarlberg) ein: " state
    read -p "Bitte gib deine Stadt (z.B. Gurtis) ein: " locality
    read -p "Bitte gib deine Organisation (z.B. XIIT) ein: " organization
    read -p "Bitte gib deine Organisationseinheit (z.B. IT-Abteilung) ein: " org_unit
    read -p "Bitte gib deine E-Mail-Adresse ein: " email

    # Speichere die OpenSSL-Konfigurationsdaten in einer Datei
    cat > "$config_file" <<EOL
country="$country"
state="$state"
locality="$locality"
organization="$organization"
org_unit="$org_unit"
email="$email"
EOL
    echo "OpenSSL-Daten wurden gespeichert."
fi

# Erstelle den privaten CA-Schlüssel (myCA.key)
echo "Erstelle den privaten CA-Schlüssel..."
openssl genrsa -des3 -out myCA.key -passout pass:$ca_password 2048 || { echo "Fehler beim Erstellen des CA-Schlüssels"; exit 1; }
echo "Privater CA-Schlüssel 'myCA.key' erstellt."

# Erstelle das selbstsignierte CA-Zertifikat (myCA.pem)
echo "Erstelle das selbstsignierte CA-Zertifikat..."
openssl req -x509 -new -key myCA.key -sha256 -days 1825 -out myCA.pem -passin pass:$ca_password \
  -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$org_unit/CN=$email" || { echo "Fehler beim Erstellen des CA-Zertifikats"; exit 1; }
echo "Selbstsigniertes CA-Zertifikat 'myCA.pem' erstellt."

# Frage nach dem Domainnamen für die Zertifikatserstellung
read -p "Bitte gib den Domainnamen ein: " domain
echo

# Pfad des Zertifikatsordners für die Domain
cert_dir="$cert_base_dir/$domain"

# Prüfe, ob der Ordner für die Domain bereits existiert
if [ -d "$cert_dir" ]; then
    read -p "Der Ordner $cert_dir existiert bereits. Möchtest du ihn und dessen Inhalt überschreiben? (y/n): " choice
    if [ "$choice" != "y" ]; then
        echo "Der Ordner wird nicht überschrieben. Skript wird beendet."
        exit 0
    else
        echo "Überschreibe den Ordner $cert_dir und dessen Inhalt..."
        rm -rf "$cert_dir"
    fi
fi

# Erstelle den Ordner im Verzeichnis ~/certs und wechsle dorthin
mkdir -p "$cert_dir"
cd "$cert_dir" || { echo "Fehler beim Wechseln in das Verzeichnis"; exit 1; }

# Erstelle den privaten Schlüssel für die Domain
openssl genrsa -out "$domain.key" 2048 || { echo "Fehler beim Erstellen des privaten Schlüssels"; exit 1; }
echo "Privater Schlüssel für $domain erstellt: $domain.key"

# Erstelle eine openssl.cnf Datei mit den gespeicherten Daten
cat > openssl.cnf <<EOL
[req]
default_bits        = 2048
distinguished_name  = req_distinguished_name
req_extensions      = req_ext
prompt              = no

[req_distinguished_name]
C                   = $country
ST                  = $state
L                   = $locality
O                   = $organization
OU                  = $org_unit
CN                  = $domain
emailAddress        = $email

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $domain
EOL

# Erstelle die Zertifikatsanforderung (CSR) unter Verwendung der Konfigurationsdatei
openssl req -new -key "$domain.key" -out "$domain.csr" -config openssl.cnf || { echo "Fehler beim Erstellen der Zertifikatsanforderung"; exit 1; }
echo "Zertifikatsanforderung (CSR) für $domain erstellt: $domain.csr"

# Erstelle die .ext Datei für das Zertifikat
cat > "$domain.ext" <<EOL
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $domain
EOL
echo ".ext Datei für $domain erstellt: $domain.ext"

# Führe den OpenSSL-Befehl aus, um das Zertifikat zu erstellen (mit Passwort für myCA.key)
openssl x509 -req -in "$domain.csr" -CA ~/certs/myCA.pem -CAkey ~/certs/myCA.key -passin pass:$ca_password -CAcreateserial -out "$domain.crt" -days 825 -sha256 -extfile "$domain.ext" || { echo "Fehler beim Erstellen des Zertifikats"; exit 1; }
echo "Zertifikat für $domain erstellt: $domain.crt"

# Bestätigung der Erstellung
echo "Das Zertifikat wurde erfolgreich für die Domain $domain erstellt und befindet sich im Verzeichnis $cert_dir"
#!/bin/bash

# Funktion zum sicheren Generieren eines zufälligen Passworts mit mindestens 32 Zeichen (alphanumerisch)
generate_password() {
    echo "$(openssl rand -base64 32)"
}

# Stelle sicher, dass das Verzeichnis 'certs' existiert
cert_base_dir=~/certs
if [ ! -d "$cert_base_dir" ]; then
    echo "Das Verzeichnis 'certs' existiert nicht. Erstelle das Verzeichnis..."
    mkdir -p "$cert_base_dir" || { echo "Fehler beim Erstellen des Verzeichnisses"; exit 1; }
    echo "'certs'-Verzeichnis erstellt."
fi

# Wechsle in das 'certs'-Verzeichnis
cd "$cert_base_dir" || { echo "Fehler beim Wechseln in das Verzeichnis"; exit 1; }

# Prüfe, ob bereits Konfigurationsdaten und das Passwort existieren
config_file="$cert_base_dir/openssl_data.conf"
password_file="$cert_base_dir/cpearst"

if [ -f "$config_file" ] && [ -f "$password_file" ]; then
    echo "Verwende gespeicherte OpenSSL-Daten und Passwort."
    source "$config_file"
    ca_password=$(cat "$password_file")
else
    # Frage den Benutzer, ob er ein sicheres Passwort automatisch generieren lassen möchte
    read -p "Möchtest du ein sicheres Passwort automatisch generieren lassen? (y/n): " generate_pass
    if [ "$generate_pass" == "y" ]; then
        ca_password=$(generate_password)
        echo "Automatisch generiertes Passwort: $ca_password"
        echo "Das Passwort wird in der Datei 'cpearst' im Ordner 'certs' gespeichert."
        echo "$ca_password" > "$password_file"
        echo "Bitte notiere dieses Passwort sicher und lösche die Datei 'cpearst', sobald du es nicht mehr benötigst."
    else
        read -sp "Bitte gib ein Passwort für myCA.key ein: " ca_password
        echo
        read -p "Möchtest du das Passwort im 'certs'-Ordner speichern? (y/n): " save_pass
        if [ "$save_pass" == "y" ]; then
            echo "$ca_password" > "$password_file"
            echo "Das Passwort wurde in der Datei 'cpearst' im Ordner 'certs' gespeichert. Bitte lösche diese Datei, sobald du das Passwort nicht mehr benötigst."
        else
            echo "Bitte notiere das Passwort sicher."
        fi
    fi

    # Frage nach den OpenSSL-Konfigurationsdaten
    read -p "Bitte gib dein Landeskürzel (z.B. AT) ein: " country
    read -p "Bitte gib dein Bundesland (z.B. Vorarlberg) ein: " state
    read -p "Bitte gib deine Stadt (z.B. Gurtis) ein: " locality
    read -p "Bitte gib deine Organisation (z.B. XIIT) ein: " organization
    read -p "Bitte gib deine Organisationseinheit (z.B. IT-Abteilung) ein: " org_unit
    read -p "Bitte gib deine E-Mail-Adresse ein: " email

    # Speichere die OpenSSL-Konfigurationsdaten in einer Datei
    cat > "$config_file" <<EOL
country="$country"
state="$state"
locality="$locality"
organization="$organization"
org_unit="$org_unit"
email="$email"
EOL
    echo "OpenSSL-Daten wurden gespeichert."
fi

# Erstelle den privaten CA-Schlüssel (myCA.key)
echo "Erstelle den privaten CA-Schlüssel..."
openssl genrsa -des3 -out myCA.key -passout pass:$ca_password 2048 || { echo "Fehler beim Erstellen des CA-Schlüssels"; exit 1; }
echo "Privater CA-Schlüssel 'myCA.key' erstellt."

# Erstelle das selbstsignierte CA-Zertifikat (myCA.pem)
echo "Erstelle das selbstsignierte CA-Zertifikat..."
openssl req -x509 -new -key myCA.key -sha256 -days 1825 -out myCA.pem -passin pass:$ca_password \
  -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$org_unit/CN=$email" || { echo "Fehler beim Erstellen des CA-Zertifikats"; exit 1; }
echo "Selbstsigniertes CA-Zertifikat 'myCA.pem' erstellt."

# Frage nach dem Domainnamen für die Zertifikatserstellung
read -p "Bitte gib den Domainnamen ein: " domain
echo

# Pfad des Zertifikatsordners für die Domain
cert_dir="$cert_base_dir/$domain"

# Prüfe, ob der Ordner für die Domain bereits existiert
if [ -d "$cert_dir" ]; then
    read -p "Der Ordner $cert_dir existiert bereits. Möchtest du ihn und dessen Inhalt überschreiben? (y/n): " choice
    if [ "$choice" != "y" ]; then
        echo "Der Ordner wird nicht überschrieben. Skript wird beendet."
        exit 0
    else
        echo "Überschreibe den Ordner $cert_dir und dessen Inhalt..."
        rm -rf "$cert_dir"
    fi
fi

# Erstelle den Ordner im Verzeichnis ~/certs und wechsle dorthin
mkdir -p "$cert_dir"
cd "$cert_dir" || { echo "Fehler beim Wechseln in das Verzeichnis"; exit 1; }

# Erstelle den privaten Schlüssel für die Domain
openssl genrsa -out "$domain.key" 2048 || { echo "Fehler beim Erstellen des privaten Schlüssels"; exit 1; }
echo "Privater Schlüssel für $domain erstellt: $domain.key"

# Erstelle eine openssl.cnf Datei mit den gespeicherten Daten
cat > openssl.cnf <<EOL
[req]
default_bits        = 2048
distinguished_name  = req_distinguished_name
req_extensions      = req_ext
prompt              = no

[req_distinguished_name]
C                   = $country
ST                  = $state
L                   = $locality
O                   = $organization
OU                  = $org_unit
CN                  = $domain
emailAddress        = $email

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $domain
EOL

# Erstelle die Zertifikatsanforderung (CSR) unter Verwendung der Konfigurationsdatei
openssl req -new -key "$domain.key" -out "$domain.csr" -config openssl.cnf || { echo "Fehler beim Erstellen der Zertifikatsanforderung"; exit 1; }
echo "Zertifikatsanforderung (CSR) für $domain erstellt: $domain.csr"

# Erstelle die .ext Datei für das Zertifikat
cat > "$domain.ext" <<EOL
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $domain
EOL
echo ".ext Datei für $domain erstellt: $domain.ext"

# Führe den OpenSSL-Befehl aus, um das Zertifikat zu erstellen (mit Passwort für myCA.key)
openssl x509 -req -in "$domain.csr" -CA ~/certs/myCA.pem -CAkey ~/certs/myCA.key -passin pass:$ca_password -CAcreateserial -out "$domain.crt" -days 825 -sha256 -extfile "$domain.ext" || { echo "Fehler beim Erstellen des Zertifikats"; exit 1; }
echo "Zertifikat für $domain erstellt: $domain.crt"

# Bestätigung der Erstellung
echo "Das Zertifikat wurde erfolgreich für die Domain $domain erstellt und befindet sich im Verzeichnis $cert_dir"
