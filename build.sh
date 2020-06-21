#!/usr/bin/env bash
#
# Copyright (C) 2020 CesiumOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#

# Global variables
DEVICE="$1"
SYNC="$2"
CLEAN="$3"
CCACHE="$4"
JOBS="$(($(nproc --all)-2))"

# Colors makes things beautiful
export TERM=xterm
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
blu=$(tput setaf 4)             #  blue
cya=$(tput setaf 6)             #  cyan
txtrst=$(tput sgr0)             #  Reset

function exports() {
   export CUSTOM_BUILD_TYPE=OFFICIAL
   export KBUILD_BUILD_HOST="NexusPenguin"
}

function sync() {
    # It's time to sync!
   git config --global user.name "SahilSonar"
   git config --global user.email "sss.sonar2003@gmail.com"
   echo -e ${blu} "[*] Syncing sources... This will take a while" ${txtrst}
   rm -rf .repo/local_manifests
   repo init --depth=1 -u git://github.com/CesiumOS-org/manifest.git -b ten
   repo sync -c -j"$JOBS" --no-tags --no-clone-bundle --force-sync
   echo -e ${cya} "[*] Syncing sources completed!" ${txtrst}
}

function signing_keys() {
   echo -e ${blu} "[*] Importing certs..." ${txtrst}
   git clone git@github.com:CesiumOS-org/test-keys.git .certs
   export SIGNING_KEYS=.certs
   echo -e ${grn} "[*] Imported certs sucessfully!" ${txtrst}
}

function track_private() {
   echo -e ${blu} "[*] Fetching private repos..." ${txtrst}
   rm -rf packages/apps/Settings
   rm -rf vendor/cesiumstyle
   git clone git@github.com:CesiumOS-org/android_packages_apps_Settings.git packages/apps/Settings
   git clone git@github.com:CesiumOS-org/android_vendor_cesiumstyle.git vendor/cesiumstyle
   echo -e ${cya} "[*] Fetched private repos successfully!" ${txtrst}
}

function use_ccache() {
    # CCACHE UMMM!!! Cooks my builds fast
   if [ "$CCACHE" = "true" ]; then
      export CCACHE_DIR=/mnt/NEW-FILES/workspace/jenkins-ccache
      ccache -M 75G
      export CCACHE_EXEC=$(which ccache)
      export USE_CCACHE=1
   echo -e ${blu} "[*] Yumm! ccache enabled!" ${txtrst}
   elif [ "$CCACHE" = "false" ]; then
      export CCACHE_DIR=/mnt/NEW-FILES/workspace/jenkins-ccache
      ccache -C
   echo -e ${grn} "[*] Ugh! ccache cleaned!" ${txtrst}
   fi
}

function clean_up() {
  # It's Clean Time
   if [ "$CLEAN" = "true" ]; then
   echo -e ${blu}"[*] Running clean job - full" ${txtrst}
      make clean && make clobber
   echo -e ${grn}"[*] Clean job completed!" ${txtrst}
   elif [ "$CLEAN" = "false" ]; then
   echo -e ${blu}"[*] Running clean job - install" ${txtrst}
       make installclean
   echo -e ${cya}"[*] make installclean completed!" ${txtrst}

    fi
}

function build_main() {
  # It's build time! YASS
   source build/envsetup.sh
   echo -e ${blu}"[*] Starting the build..." ${txtrst}
   lunch cesium_${DEVICE}-userdebug
   mka bacon -j"$JOBS"
}

function build_end() {
  # It's upload time!
   echo -e ${blu}"[*] Uploading the build & json..." ${txtrst}
      rsync -azP  -e ssh out/target/product/"$DEVICE"/CesiumOS*.zip sahilsonar2003@frs.sourceforge.net:/home/frs/project/cesiumos-org/"$DEVICE"/
      rsync -azP  -e ssh out/target/product/"$DEVICE"/CesiumOS*.zip.json sahilsonar2003@frs.sourceforge.net:/home/frs/project/cesiumos-org/"$DEVICE"/
      cat out/target/product/"$DEVICE"/CesiumOS*.zip.json
   echo -e ${cyn}"[*] Cleaning up certs..." ${txtrst}
      rm -rf .certs
   echo -e ${grn}"[*] Removed the certs sucessfully!..." ${txtrst}
   echo -e ${blu}"[*] Removing private repos..." ${txtrst}
      rm -rf packages/apps/Settings && rm -rf vendor/cesiumstyle
   echo -e ${blu}"[*] Removed private repos!" ${txtrst}
}

exports
if [ "$SYNC" = "true" ]; then
    sync
    track_private
fi
signing_keys
use_ccache
clean_up
build_main
build_end
