#!/usr/bin/env bash
set -euo pipefail
APP_DIR="/var/www/parspec"
VENV_DIR="$APP_DIR/venv"
SITE_CONF="/etc/apache2/sites-available/parspec.conf"

sudo apt update
sudo apt -y install apache2 libapache2-mod-wsgi-py3 python3-venv python3-pip libapache2-mod-security2 unzip curl
sudo a2enmod wsgi headers proxy proxy_http security2 || true
sudo systemctl enable --now apache2

sudo mkdir -p $APP_DIR
sudo chown -R www-data:www-data $APP_DIR
sudo chmod -R 775 $APP_DIR

SRC_DIR="/home/ubuntu/parspec-sqli-flask"
sudo rsync -a --delete "$SRC_DIR/app/" "$APP_DIR/"

sudo -u www-data python3 -m venv "$VENV_DIR"
sudo -u www-data bash -lc "$VENV_DIR/bin/pip install --upgrade pip"
sudo -u www-data bash -lc "$VENV_DIR/bin/pip install flask==3.0.3"

sudo -u www-data bash -lc "cd $APP_DIR && $VENV_DIR/bin/python db_init.py"

if [ ! -f /etc/modsecurity/modsecurity.conf ]; then
  sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
fi
sudo sed -i 's/^SecRuleEngine.*/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf

sudo mkdir -p /etc/modsecurity/crs
cd /etc/modsecurity/crs
sudo curl -L -o crs.zip https://github.com/coreruleset/coreruleset/archive/refs/heads/v4.0/dev.zip
sudo unzip -o crs.zip
sudo rm -f crs.zip
CRS_DIR=$(ls -d coreruleset-*/ | head -n1 | tr -d '/')
sudo rm -rf /etc/modsecurity/crs/owasp-crs
sudo mv "$CRS_DIR" /etc/modsecurity/crs/owasp-crs
sudo cp /etc/modsecurity/crs/owasp-crs/crs-setup.conf.example /etc/modsecurity/crs/crs-setup.conf
sudo ln -sf /etc/modsecurity/crs/owasp-crs/rules /etc/modsecurity/crs/rules

sudo mkdir -p /etc/modsecurity/custom
sudo cp "$SRC_DIR/modsecurity/custom-rules.conf" /etc/modsecurity/custom/custom-rules.conf

sudo tee /etc/apache2/mods-enabled/security2.conf > /dev/null <<'APACHE'
<IfModule security2_module>
    SecDataDir /var/cache/modsecurity
    IncludeOptional /etc/modsecurity/*.conf
    IncludeOptional /etc/modsecurity/crs/crs-setup.conf
    IncludeOptional /etc/modsecurity/crs/rules/*.conf
    IncludeOptional /etc/modsecurity/custom/*.conf
</IfModule>
APACHE

sudo cp "$SRC_DIR/apache/parspec.conf" "$SITE_CONF"
sudo a2dissite 000-default.conf || true
sudo a2ensite parspec.conf
sudo systemctl restart apache2

echo "Visit: http://<EC2_PUBLIC_IP>/page1.html (vulnerable)"
echo "Visit: http://<EC2_PUBLIC_IP>/page2.html (protected)"
