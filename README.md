# Parspec SQLi Assignment — Flask + Apache + ModSecurity

## Deliverables
- Exploitable:  `http://<EC2_PUBLIC_IP>/page1.html`
- Non-exploitable: `http://<EC2_PUBLIC_IP>/page2.html`

## Quick Start on EC2
1. Launch EC2 Ubuntu 22.04
2. SSH in
3. Clone this repo
4. Run setup: `chmod +x scripts/setup.sh && sudo scripts/setup.sh`
5. Test URLs above

## Test SQLi
- Vulnerable: username `' OR '1'='1`
- Protected: same payload returns 403

## Logs
- Apache: `/var/log/apache2/parspec_access.log`, `/var/log/apache2/parspec_error.log`
- ModSecurity: `/var/log/apache2/modsec_audit.log`

## Notes
- Flask + SQLite
- WAF: ModSecurity + OWASP CRS + custom rules

## Cleanup
Terminate EC2 after submission.
