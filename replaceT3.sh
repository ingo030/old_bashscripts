#!/bin/bash

#############################################
#############################################
### Remove old DDEV Project and add new
### touch replaceT3.sh && chmod u+x replaceT3.sh && vim replaceT3.sh && source replaceT3.sh
#############################################
#############################################
#scp live-dump.sql ../files.inkasso.de/live-dump.sql
#scp live-fileadmin.tar.gz ../files.inkasso.de/live-fileadmin.tar.gz
#tar xOf ../files.inkasso.de/live-fileadmin.tar.gz &> /dev/null; echo 0

echo '... mkdir -p ../files.inkasso.de && cp .env ../files.inkasso.de/.env.inkasso'
mkdir -p ../files.inkasso.de && cp .env ../files.inkasso.de/.env.inkasso
echo 'ddev clean local-inkasso'
ddev clean local-inkasso
echo '... ddev stop && ddev delete --omit-snapshot local-inkasso'
ddev stop && ddev delete --omit-snapshot local-inkasso
echo '... rm -rf * .* && git clone -b typo3-12.4 git@bitbucket.org:goldland/inkasso_bundle.git .'
rm -rf * .* && git clone -b typo3-12.4 git@bitbucket.org:goldland/inkasso_bundle.git .
echo '... ddev start && ddev auth ssh && ddev composer install --no-scripts'
ddev start && ddev auth ssh && ddev composer install --no-scripts
echo '... ddev import-db --file=../files.inkasso.de/live-dump.sql'
ddev import-db --file=../files.inkasso.de/live-dump.sql
echo '... cp ../files.inkasso.de/.env.inkasso .env && cat .env'
cp ../files.inkasso.de/.env.inkasso .env && cat .env
echo '... mkdir -p public/fileadmin'
mkdir -p public/fileadmin
echo '... tar xzf ../files.inkasso.de/live-fileadmin.tar.gz -C public/fileadmin'
tar xzf ../files.inkasso.de/live-fileadmin.tar.gz -C public/fileadmin
echo '... ddev composer install'
ddev composer install
echo '... ddev add-on get ddev/ddev-phpmyadmin'
ddev add-on get ddev/ddev-phpmyadmin
