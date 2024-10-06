#!/bin/bash

# Function to securely generate a random password with at least 32 alphanumeric characters
generate_password() {
    echo "$(openssl rand -base64 32)"
}

# Function for language selection
select_language() {
    echo "Please choose your language:"
    echo "1) English"
    echo "2) Deutsch"
    echo "3) Français"
    read -p "Enter the number corresponding to your language: " language_choice

    case $language_choice in
        1)
            language="en"
            ;;
        2)
            language="de"
            ;;
        3)
            language="fr"
            ;;
        *)
            echo "Invalid selection. Defaulting to English."
            language="en"
            ;;
    esac
}

# Load the appropriate messages based on language selection
load_language_messages() {
    case $language in
        "en")
            msg_generate_password="Would you like to generate a secure password automatically? (y/n): "
            msg_automatically_generated_password="Automatically generated password: "
            msg_password_saved="The password will be saved in the 'cpearst' file in the 'certs' directory."
            msg_note_password="Please securely record this password and delete the 'cpearst' file once you no longer need it."
            msg_enter_password="Please enter a password for myCA.key: "
            msg_save_password="Do you want to save the password in the 'certs' directory? (y/n): "
            msg_record_password="Please securely record the password."
            msg_country="Please enter your country code (e.g., US): "
            msg_state="Please enter your state (e.g., California): "
            msg_locality="Please enter your city (e.g., Los Angeles): "
            msg_organization="Please enter your organization (e.g., MyCompany): "
            msg_org_unit="Please enter your organizational unit (e.g., IT Department): "
            msg_email="Please enter your email address: "
            msg_openssl_saved="OpenSSL data has been saved."
            msg_create_ca_key="Generating the private CA key..."
            msg_ca_key_created="Private CA key 'myCA.key' created."
            msg_create_ca_cert="Creating the self-signed CA certificate..."
            msg_ca_cert_created="Self-signed CA certificate 'myCA.pem' created."
            msg_enter_domain="Please enter the domain name: "
            msg_directory_exists="The directory already exists. Do you want to overwrite it and its contents? (y/n): "
            msg_directory_not_overwritten="The directory will not be overwritten. Exiting script."
            msg_directory_overwritten="Overwriting the directory and its contents..."
            msg_directory_created="Directory created."
            msg_private_key_created="Private key for the domain created."
            msg_certificate_created="Certificate created for the domain."
            ;;
        "de")
            msg_generate_password="Möchtest du ein sicheres Passwort automatisch generieren lassen? (y/n): "
            msg_automatically_generated_password="Automatisch generiertes Passwort: "
            msg_password_saved="Das Passwort wird in der Datei 'cpearst' im Verzeichnis 'certs' gespeichert."
            msg_note_password="Bitte notiere dieses Passwort sicher und lösche die Datei 'cpearst', sobald du es nicht mehr benötigst."
            msg_enter_password="Bitte gib ein Passwort für myCA.key ein: "
            msg_save_password="Möchtest du das Passwort im Verzeichnis 'certs' speichern? (y/n): "
            msg_record_password="Bitte notiere das Passwort sicher."
            msg_country="Bitte gib dein Landeskürzel ein (z.B. DE): "
            msg_state="Bitte gib dein Bundesland ein (z.B. Bayern): "
            msg_locality="Bitte gib deine Stadt ein (z.B. München): "
            msg_organization="Bitte gib deine Organisation ein (z.B. MeineFirma): "
            msg_org_unit="Bitte gib deine Organisationseinheit ein (z.B. IT-Abteilung): "
            msg_email="Bitte gib deine E-Mail-Adresse ein: "
            msg_openssl_saved="OpenSSL-Daten wurden gespeichert."
            msg_create_ca_key="Erstelle den privaten CA-Schlüssel..."
            msg_ca_key_created="Privater CA-Schlüssel 'myCA.key' erstellt."
            msg_create_ca_cert="Erstelle das selbstsignierte CA-Zertifikat..."
            msg_ca_cert_created="Selbstsigniertes CA-Zertifikat 'myCA.pem' erstellt."
            msg_enter_domain="Bitte gib den Domainnamen ein: "
            msg_directory_exists="Das Verzeichnis existiert bereits. Möchtest du es und seinen Inhalt überschreiben? (y/n): "
            msg_directory_not_overwritten="Das Verzeichnis wird nicht überschrieben. Skript wird beendet."
            msg_directory_overwritten="Überschreibe das Verzeichnis und seinen Inhalt..."
            msg_directory_created="Verzeichnis erstellt."
            msg_private_key_created="Privater Schlüssel für die Domain erstellt."
            msg_certificate_created="Zertifikat für die Domain erstellt."
            ;;
        "fr")
            msg_generate_password="Voulez-vous générer automatiquement un mot de passe sécurisé? (y/n): "
            msg_automatically_generated_password="Mot de passe généré automatiquement: "
            msg_password_saved="Le mot de passe sera enregistré dans le fichier 'cpearst' dans le répertoire 'certs'."
            msg_note_password="Veuillez enregistrer ce mot de passe en toute sécurité et supprimer le fichier 'cpearst' une fois que vous n'en avez plus besoin."
            msg_enter_password="Veuillez entrer un mot de passe pour myCA.key: "
            msg_save_password="Voulez-vous enregistrer le mot de passe dans le répertoire 'certs'? (y/n): "
            msg_record_password="Veuillez enregistrer le mot de passe en toute sécurité."
            msg_country="Veuillez entrer votre code pays (par exemple, FR): "
            msg_state="Veuillez entrer votre région (par exemple, Île-de-France): "
            msg_locality="Veuillez entrer votre ville (par exemple, Paris): "
            msg_organization="Veuillez entrer votre organisation (par exemple, MaCompagnie): "
            msg_org_unit="Veuillez entrer votre unité organisationnelle (par exemple, Département IT): "
            msg_email="Veuillez entrer votre adresse e-mail: "
            msg_openssl_saved="Les données OpenSSL ont été enregistrées."
            msg_create_ca_key="Génération de la clé privée CA..."
            msg_ca_key_created="Clé privée CA 'myCA.key' créée."
            msg_create_ca_cert="Création du certificat CA auto-signé..."
            msg_ca_cert_created="Certificat CA auto-signé 'myCA.pem' créé."
            msg_enter_domain="Veuillez entrer le nom de domaine: "
            msg_directory_exists="Le répertoire existe déjà. Voulez-vous le remplacer et son contenu? (y/n): "
            msg_directory_not_overwritten="Le répertoire ne sera pas remplacé. Fin du script."
            msg_directory_overwritten="Remplacement du répertoire et de son contenu..."
            msg_directory_created="Répertoire créé."
            msg_private_key_created="Clé privée pour le domaine créée."
            msg_certificate_created="Certificat créé pour le domaine."
            ;;
    esac
}

# Start the script by selecting the language
select_language
load_language_messages

# Begin the script logic, using the language-specific messages for each prompt

# Ensure that the 'certs' directory exists
cert_base_dir=~/certs
if [ ! -d "$cert_base_dir" ]; then
    echo "$msg_directory_created"
    mkdir -p "$cert_base_dir" || { echo "Error creating the directory"; exit 1; }
fi

# Change to the 'certs' directory
cd "$cert_base_dir" || { echo "Error changing to the directory"; exit 1; }

# Check if configuration data and password already exist
config_file="$cert_base_dir/openssl_data.conf"
password_file="$cert_base_dir/cpearst"

if [ -f "$config_file" ] && [ -f "$password_file" ]; then
    echo "Using saved OpenSSL data and password."
    source "$config_file"
    ca_password=$(cat "$password_file")
else
    # Ask the user if they want to automatically generate a secure password
    read -p "$msg_generate_password" generate_pass
    if [ "$generate_pass" == "y" ]; then
        ca_password=$(generate_password)
        echo "$msg_automatically_generated_password $ca_password"
        echo "$msg_password_saved"
        echo "$ca_password" > "$password_file"
        echo "$msg_note_password"
    else
        read -sp "$msg_enter_password" ca_password
        echo
        read -p "$msg_save_password" save_pass
        if [ "$save_pass" == "y" ]; then
            echo "$ca_password" > "$password_file"
            echo "$msg_note_password"
        else
            echo "$msg_record_password"
        fi
    fi

    # Ask for OpenSSL configuration data
    read -p "$msg_country" country
    read -p "$msg_state" state
    read -p "$msg_locality" locality
    read -p "$msg_organization" organization
    read -p "$msg_org_unit" org_unit
    read -p "$msg_email" email

    # Save OpenSSL configuration data to a file
    cat > "$config_file" <<EOL
country="$country"
state="$state"
locality="$locality"
organization="$organization"
org_unit="$org_unit"
email="$email"
EOL
    echo "$msg_openssl_saved"
fi

# Generate the private CA key (myCA.key)
echo "$msg_create_ca_key"
openssl genrsa -des3 -out myCA.key -passout pass:$ca_password 2048 || { echo "Error generating the CA key"; exit 1; }
echo "$msg_ca_key_created"

# Create the self-signed CA certificate (myCA.pem)
echo "$msg_create_ca_cert"
openssl req -x509 -new -key myCA.key -sha256 -days 1825 -out myCA.pem -passin pass:$ca_password \
  -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$org_unit/CN=$email" || { echo "Error creating the CA certificate"; exit 1; }
echo "$msg_ca_cert_created"

# Ask for the domain name for the certificate creation
read -p "$msg_enter_domain" domain
echo

# Path for the domain certificate directory
cert_dir="$cert_base_dir/$domain"

# Check if the directory for the domain already exists
if [ -d "$cert_dir" ]; then
    read -p "$msg_directory_exists" choice
    if [ "$choice" != "y" ]; then
        echo "$msg_directory_not_overwritten"
        exit 0
    else
        echo "$msg_directory_overwritten"
        rm -rf "$cert_dir"
    fi
fi

# Create the directory and switch to it
mkdir -p "$cert_dir"
cd "$cert_dir" || { echo "Error changing to the directory"; exit 1; }

# Generate the private key for the domain
openssl genrsa -out "$domain.key" 2048 || { echo "Error generating the private key"; exit 1; }
echo "$msg_private_key_created $domain.key"

# Create the openssl.cnf file with saved data
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

# Create the certificate signing request (CSR)
openssl req -new -key "$domain.key" -out "$domain.csr" -config openssl.cnf || { echo "Error creating the CSR"; exit 1; }
echo "$msg_certificate_created $domain"
