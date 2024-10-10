
#!/bin/bash
mkdir /opt/mailcow-dockerized/data/assets/ssl/tempCert

######################## Change HostB and HostA to your need
ssh root@hostB 'for type in fullchain privkey; do 
  file=$(ls /usr/share/hassio/addon_configs/a0d7b954_nginxproxymanager/letsencrypt/archive/npm-34/${type}*.pem 2>/dev/null | sort -V | tail -n 1)
  if [ -n "$file" ]; then
    echo "$file"
    scp "$file" root@hostA:/opt/mailcow-dockerized/data/assets/ssl/tempCert/
  fi
done'


for type in fullchain privkey; do
  file="/opt/mailcow-dockerized/data/assets/ssl/tempCert/${type}*.pem"  # Trouve tous les fichiers correspondant au type
  for f in $file; do
    if [ -f "$f" ]; then
      new_file="${f%[0-9].pem}.pem" 
      echo "Renommage de $f en $new_file"
      mv "$f" "$new_file"  # Renomme le fichier
    fi
  done
done

mv /opt/mailcow-dockerized/data/assets/ssl/tempCert/fullchain.pem /opt/mailcow-dockerized/data/assets/ssl/tempCert/cert.pem
mv /opt/mailcow-dockerized/data/assets/ssl/tempCert/privkey.pem /opt/mailcow-dockerized/data/assets/ssl/tempCert/key.pem

hash1=$(openssl x509 -in /opt/mailcow-dockerized/data/assets/ssl/cert.pem -noout -fingerprint -sha256 | awk -F= '{print $2}')
hash2=$(openssl x509 -in /opt/mailcow-dockerized/data/assets/ssl/tempCert/cert.pem -noout -fingerprint -sha256 | awk -F= '{print $2}')

if [ "$hash1" == "$hash2" ]; then
    echo " $(date) : Certs are the sames." >> /root/certupdate.log
else
    echo " $(date) : Certs are different" >> /root/certupdate.log
        cp -r /opt/mailcow-dockerized/data/assets/ssl/ /opt/mailcow-dockerized/data/assets/sslBackupCert
        cp /opt/mailcow-dockerized/data/assets/ssl/tempCert/* /opt/mailcow-dockerized/data/assets/ssl/
        docker restart $(docker ps -qaf name=postfix-mailcow)
        docker restart $(docker ps -qaf name=nginx-mailcow)
        docker restart $(docker ps -qaf name=dovecot-mailcow)
fi

### Tips
#cp /etc/letsencrypt/live/MAILCOW_HOSTNAME/fullchain.pem ./data/assets/ssl/cert.pem
#cp /etc/letsencrypt/live/MAILCOW_HOSTNAME/privkey.pem ./data/assets/ssl/key.pem
