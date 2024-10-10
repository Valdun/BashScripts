#!/bin/bash
mkdir /etc/letsencrypt/archive/tmp/
######################## Change HostB and HostRMM to your need
ssh root@hostB 'for type in cert chain fullchain privkey; do
  file=$(ls /usr/share/hassio/addon_configs/a0d7b954_nginxproxymanager/letsencrypt/archive/npm-34/${type}*.pem 2>/dev/null | sort -V | tail -n 1)
  if [ -n "$file" ]; then
    echo "$file"
    scp "$file" root@RMMHost:/etc/letsencrypt/archive/tmp/
  fi
done'


for type in cert chain fullchain privkey; do
  file="/etc/letsencrypt/archive/tmp/${type}*.pem"  # Trouve tous les fichiers correspondant au type
  for f in $file; do
    if [ -f "$f" ]; then
      new_file="${f%[0-9].pem}3.pem"  # Remplace le dernier chiffre par 3
      echo "Renommage de $f en $new_file"
      mv "$f" "$new_file"  # Renomme le fichier
    fi
  done
done

################### change <<yourdomain>>
hash1=$(openssl x509 -in /etc/letsencrypt/archive/tmp/cert.pem -noout -fingerprint -sha256 | awk -F= '{print $2}')
hash2=$(openssl x509 -in  /etc/letsencrypt/archive/<<yourdomain>>/cert.pem -noout -fingerprint -sha256 | awk -F= '{print $2}')

if [ "$hash1" == "$hash2" ]; then
    echo " $(date) : Certs are the sames." >> /root/certupdate.log
else
    echo " $(date) : Certs are different." >> /root/certupdate.log
################### change <<yourdomain>>
	cp /etc/letsencrypt/archive/tmp/* /etc/letsencrypt/archive/<<yourdomain>>/ 
	 sudo -u tactical /home/tactical/update.sh --force
fi

