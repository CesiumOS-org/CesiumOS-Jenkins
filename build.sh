#!/usr/bin/env bash
#
# Copyright (C) 2020-2021 The CesiumOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#

# Global variables
DEVICE="$1"
BUILD_TYPE="$2"
BUILD_DEBUG="$3"
SYNC="$4"
CLEAN="$5"
CCACHE="$6"

# Colors makes things beautiful
export TERM=xterm
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
blu=$(tput setaf 4)             #  blue
cya=$(tput setaf 6)             #  cyan
txtrst=$(tput sgr0)             #  Reset

sendMessage() {
    MESSAGE=$1
    curl -s "https://api.telegram.org/bot${BOT_API_KEY}/sendmessage" --data "text=$MESSAGE&chat_id=-1001261572458" 1>/dev/null
    echo -e
}

function exports() {
   sendMessage "Build triggered on Jenkins for ${DEVICE}"
   export CUSTOM_BUILD_TYPE=${BUILD_TYPE}
}

function sync() {
    # It's time to sync!
   git config --global user.name "SahilSonar"
   git config --global user.email "sss.sonar2003@gmail.com"
   echo -e ${blu} "[*] Syncing sources... This will take a while" ${txtrst}
   sendMessage "Starting repo sync. Executing command: repo sync"
   rm -rf .repo/local_manifests
   repo init --depth=1 -u git://github.com/CesiumOS-org/manifest.git -b eleven
   repo sync -c -j$(nproc --all) --no-tags --no-clone-bundle --force-sync
   echo -e ${cya} "[*] Syncing sources completed!" ${txtrst}
}

function signing_keys() {
   echo -e ${blu} "[*] Importing certs..." ${txtrst}
   git clone git@github.com:CesiumOS-org/test-keys.git .certs
   export SIGNING_KEYS=.certs
   echo -e ${grn} "[*] Imported certs sucessfully!" ${txtrst}
}

function use_ccache() {
    # CCACHE UMMM!!! Cooks my builds fast
   if [ "$CCACHE" = "true" ]; then
      export CCACHE_DIR=/mnt/FILES/workspace/CesiumOS-ccache
      ccache -M 80G
      export CCACHE_EXEC=$(which ccache)
      export USE_CCACHE=1
   echo -e ${blu} "[*] Yumm! ccache enabled!" ${txtrst}
   elif [ "$CCACHE" = "false" ]; then
      export CCACHE_DIR=/mnt/FILES/workspace/CesiumOS-ccache
      ccache -C
   echo -e ${grn} "[*] Ugh! ccache cleaned!" ${txtrst}
   fi
}

function clean_up() {
  # It's Clean Time
   source build/envsetup.sh
   if [ "$CLEAN" = "true" ]; then
   echo -e ${blu}"[*] Running clean job - full" ${txtrst}
      make clean && make clobber
   echo -e ${grn}"[*] Clean job completed!" ${txtrst}
   elif [ "$CLEAN" = "false" ]; then
   echo -e ${blu}"[*] Running clean job - install" ${txtrst}
       lunch cesium_${DEVICE}-${BUILD_DEBUG}
       m installclean
   echo -e ${cya}"[*] make installclean completed!" ${txtrst}
   else
     # Don't do anything
    echo -e ${cya}"[*] Doing dirty build kk" ${txtrst}
    fi
}

function build_main() {
  # It's build time! YASS
   source build/envsetup.sh
   echo -e ${blu}"[*] Starting the build..." ${txtrst}
   sendMessage "Starting ${DEVICE}-${BUILD_TYPE} build, check progress here ${BUILD_URL}"
   lunch cesium_${DEVICE}-${BUILD_DEBUG}
   m bacon
   if [ $? -eq 0 ]; then
      echo -e ${grn}"[*] Build was successful!" ${txtrst}
      sendMessage "${DEVICE} build is done, check jenkins (${BUILD_URL}) for details!"
   else
      echo -e ${red}"[!] Could not build some targets, exiting.." ${txtrst}
      sendMessage "${DEVICE} build is failed, check jenkins (${BUILD_URL}) for details!"
      exit 1
   fi
}

function build_end() {
  # It's upload time!
   sendMessage "Uploading ${DEVICE} build"
   echo -e ${blu}"[*] Uploading the build & json..." ${txtrst}
   if [ "${BUILD_TYPE}" = "OFFICIAL" ]; then
      rsync -azP  -e ssh out/target/product/"$DEVICE"/CesiumOS*OFFICIAL*.zip sahilsonar2003@frs.sourceforge.net:/home/frs/project/cesiumos-org/"$DEVICE"/
      rsync -azP  -e ssh out/target/product/"$DEVICE"/CesiumOS*OFFICIAL*.zip.json sahilsonar2003@frs.sourceforge.net:/home/frs/project/cesiumos-org/"$DEVICE"/
      sendMessage "Build done, download and test fast"
      sendMessage "https://sf.net/projects/cesiumos-org/files/${DEVICE}"
   elif [ "${BUILD_TYPE}" = "BETA" ]; then
      rsync -azP  -e ssh out/target/product/"$DEVICE"/CesiumOS*BETA*.zip sahilsonar2003@frs.sourceforge.net:/home/frs/project/cesiumos-org/beta/"$DEVICE"/
      rsync -azP  -e ssh out/target/product/"$DEVICE"/CesiumOS*BETA*.zip.json sahilsonar2003@frs.sourceforge.net:/home/frs/project/cesiumos-org/beta/"$DEVICE"/
      sendMessage "Build done, download and test fast"
      sendMessage "https://sf.net/projects/cesiumos-org/files/beta/${DEVICE}"
   fi
      cat out/target/product/"$DEVICE"/CesiumOS*.zip.json
   echo -e ${cyn}"[*] Cleaning up certs..." ${txtrst}
      rm -rf .certs
   echo -e ${grn}"[*] Removed the certs sucessfully!..." ${txtrst}
}

exports
if [ "$SYNC" = "true" ]; then
    sync
fi
signing_keys
use_ccache
clean_up
build_main
build_end
