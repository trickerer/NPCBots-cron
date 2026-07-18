#!/bin/bash

# stop if any error happen
set -e

# before install
git clone --branch=${BRANCH} https://github.com/trickerer/TrinityCore-3.3.5-with-NPCBots.git $SERVER_DIR
cd $SERVER_DIR
git config user.email "github.actions@build.bot" && git config user.name "Github Actions"
git status
if [ -n "$BASE_BRANCH" ]; then
  git remote add BaseRemote https://github.com/trickerer/TrinityCore-3.3.5-with-NPCBots.git
else
  git remote add BaseRemote https://github.com/TrinityCore/TrinityCore.git
  export BASE_BRANCH=3.3.5
fi
git fetch BaseRemote ${BASE_BRANCH}
git merge -m "Merge ${BASE_BRANCH} to ${BRANCH}" BaseRemote/${BASE_BRANCH}
git submodule update --init --recursive
git status

# install
cmake -GNinja -S $SERVER_DIR -B $OUTPUT_DIR -DWITH_WARNINGS=0 -DWITH_COREDEBUG=0 -DUSE_COREPCH=1 -DUSE_SCRIPTPCH=1 -DTOOLS=0 -DSCRIPTS=dynamic -DSERVERS=1 -DNOJEM=0 -DCMAKE_C_FLAGS_DEBUG="-DNDEBUG -g0" -DCMAKE_CXX_FLAGS_DEBUG="-DNDEBUG -g0" -DCMAKE_INSTALL_PREFIX=check_install -DBUILD_TESTING=0

# script
ccache -z
cmake --build $OUTPUT_DIR
ccache -s
ccache --evict-older-than $(($EPOCHSECONDS - $BUILD_START))s
cmake --install $OUTPUT_DIR
cd $INSTALL_DIR
./authserver --version
./worldserver --version

# after success
git push https://${GITHUB_TOKEN}@github.com/trickerer/TrinityCore-3.3.5-with-NPCBots.git HEAD:${BRANCH}
