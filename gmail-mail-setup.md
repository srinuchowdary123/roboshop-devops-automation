# Gmail mail setup on roboshop-frontend

Send-only Postfix on the frontend EC2 machine. It signs in to Gmail on port 587 and sends as `srinunuthi555@gmail.com`.

The machine listens only on localhost. It is not an open mail relay.

Do not put the Gmail app password or the instance login password in git.

## 1. Start the instance

```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=roboshop-frontend" --query "Reservations[].Instances[].{Id:InstanceId,State:State.Name,PublicIp:PublicIpAddress}" --output table

aws ec2 start-instances --instance-ids i-0bc7c68ee65ea6d39

aws ec2 wait instance-running --instance-ids i-0bc7c68ee65ea6d39
```

Public IP at setup time: `54.196.178.63`. A new start can change the public IP.

## 2. Sign in

```bash
ssh ec2-user@<public-ip>
```

Login is password based. There is no SSH key on this instance.

## 3. Install the mail packages

```bash
sudo dnf install -y postfix s-nail cyrus-sasl-plain
```

`s-nail` provides the `mail` command.

## 4. Store the Gmail app password

Create the app password in the Google account under Security, App passwords. Remove the spaces before saving it. The value below is a placeholder.

```bash
sudo tee /etc/postfix/sasl_passwd >/dev/null <<'EOF'
[smtp.gmail.com]:587 srinunuthi555@gmail.com:APP_PASSWORD_WITHOUT_SPACES
EOF

sudo postmap /etc/postfix/sasl_passwd
sudo chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
sudo chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
```

## 5. Point Postfix at Gmail

```bash
sudo postconf -e "myhostname = roboshop-frontend.srinun.in"
sudo postconf -e "inet_interfaces = loopback-only"
sudo postconf -e "inet_protocols = ipv4"
sudo postconf -e "mynetworks = 127.0.0.0/8 [::1]/128"
sudo postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost"
sudo postconf -e "relayhost = [smtp.gmail.com]:587"
sudo postconf -e "smtp_sasl_auth_enable = yes"
sudo postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
sudo postconf -e "smtp_sasl_security_options = noanonymous"
sudo postconf -e "smtp_tls_security_level = encrypt"
sudo postconf -e "smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt"
```

Port 25 from this instance to the internet is blocked. Port 587 to `smtp.gmail.com` is open, so Gmail is the relay.

## 6. Let Postfix use TLS on this FIPS machine

This instance has kernel FIPS enabled. Postfix then logs `Digest algorithm "md5" not found` and turns TLS off. Gmail refuses the connection without TLS.

`/etc/postfix/openssl.cnf`:

```ini
openssl_conf = openssl_init

[openssl_init]
providers = provider_sect
alg_section = algorithm_sect

[provider_sect]
default = default_sect

[default_sect]
activate = 1

[algorithm_sect]
default_properties =
```

`/etc/systemd/system/postfix.service.d/openssl.conf`:

```ini
[Service]
Environment=OPENSSL_CONF=/etc/postfix/openssl.cnf
```

Postfix does not pass that variable to its SMTP process unless it is imported:

```bash
sudo postconf -e "import_environment = MAIL_CONFIG MAIL_DEBUG MAIL_LOGTAG TZ XAUTHORITY DISPLAY LANG=C OPENSSL_CONF"
sudo systemctl daemon-reload
sudo systemctl enable --now postfix
sudo systemctl restart postfix
```

## 7. Send a test

```bash
echo "roboshop gmail relay test" | mail -s "roboshop gmail test" -r srinunuthi555@gmail.com srinunuthi555@gmail.com
sudo postqueue -p
sudo journalctl -u postfix --since "2 min ago" --no-pager
```

A successful send looks like `status=sent (250 2.0.0 OK ...)`.

For a message from your own script:

```bash
echo "disk is full" | mail -s "disk alert" -r srinunuthi555@gmail.com srinunuthi555@gmail.com
```
