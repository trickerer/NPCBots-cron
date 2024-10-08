#!/bin/bash

# stop if any error happen
set -e

# before install
git clone --branch=${BRANCH} https://github.com/trickerer/AzerothCore-wotlk-with-NPCBots.git server
cd server
git clone --depth 1 --branch master --single-branch https://github.com/ac-data/ac-data.git build/check_install/bin
git config user.email "github.actions@build.bot" && git config user.name "Github Actions"
git status
if [ -n "$BASE_BRANCH" ]; then
  git remote add BaseRemote https://github.com/trickerer/AzerothCore-wotlk-with-NPCBots.git
else
  git remote add BaseRemote https://github.com/azerothcore/azerothcore-wotlk.git
  export BASE_BRANCH=master
fi
git fetch BaseRemote ${BASE_BRANCH}
git merge -m "Merge ${BASE_BRANCH} to ${BRANCH}" BaseRemote/${BASE_BRANCH}
git status

# install
mysql -uroot -proot -e "SET PASSWORD FOR root@localhost='';"
mysql -uroot -e 'create database test_mysql;'
cd build
cmake ../ -DWITH_WARNINGS=1 -DWITH_COREDEBUG=0 -DUSE_COREPCH=1 -DUSE_SCRIPTPCH=1 -DTOOLS=1 -DSCRIPTS=static -DMODULES=static -DSERVERS=1 -DBUILD_TESTING=ON -DNOJEM=0 -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_FLAGS_DEBUG="-DNDEBUG" -DCMAKE_CXX_FLAGS_DEBUG="-DNDEBUG" -DCMAKE_INSTALL_PREFIX=check_install
cd ..

# script
c++ --version
mysql -uroot < data/sql/create/create_mysql.sql
mysql -uroot < data/sql/create/drop_mysql.sql
mysql -uroot < data/sql/create/create_mysql.sql
cd build
make -j 4 -k && make install && make clean
cd check_install/etc
cp authserver.conf.dist authserver.conf
cp worldserver.conf.dist worldserver.conf
cd ../bin
rm -rf .git
./authserver --dry-run
./worldserver --dry-run

# after success
git push https://${GITHUB_TOKEN}@github.com/trickerer/AzerothCore-wotlk-with-NPCBots.git HEAD:${BRANCH}
