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

function exports() {
   export CUSTOM_BUILD_TYPE=OFFICIAL
   export KBUILD_BUILD_HOST="NexusPenguin"
}

function sync() {
    # It's time to sync!
   git config --global user.name "SahilSonar"
   git config --global user.email "sss.sonar2003@gmail.com"
   echo "Syncing Source, will take Little Time."
   rm -rf .repo/local_manifests
   repo init --depth=1 -u git://github.com/CesiumOS-org/manifest.git -b ten
   repo sync -c -j"$JOBS" --no-tags --no-clone-bundle
   echo "Source Synced Successfully"
}

function track_private() {
   rm -rf packages/app/Settings
   rm -rf vendor/cesiumstyle
   git clone git@github.com:CesiumOS-org/android_packages_apps_Settings.git packages/apps/Settings
   git clone git@github.com:CesiumOS-org/android_vendor_cesiumstyle.git vendor/cesiumstyle
   echo "Done tracking private repos!"
}

function use_ccache() {
    # CCACHE UMMM!!! Cooks my builds fast
   if [ "$CCACHE" = "true" ]; then
      echo "CCACHE is enabled for this build"
      export CCACHE_EXEC=$(which ccache)
      export USE_CCACHE=1
   fi
}

function clean_up() {
  # It's Clean Time
   if [ "$CLEAN" = "true" ]; then
      make clean && make clobber
   elif [ "$CLEAN" = "false" ]; then
      rm -rf out/target/product/*
      echo "Cleaning done! Ready for a sweet clean build :)"
    fi
}

function build_main() {
  # It's build time! YASS
    source build/envsetup.sh
    lunch cesium_${DEVICE}-userdebug
    mka bacon -j"$JOBS"
}

function build_end() {
  # It's upload time!
      rsync -azP  -e ssh out/target/product/"$DEVICE"/CesiumOS*.zip sahilsonar2003@frs.sourceforge.net:/home/frs/project/cesiumos-org/"$DEVICE"/
      rsync -azP  -e ssh out/target/product/"$DEVICE"/CesiumOS*.zip.json sahilsonar2003@frs.sourceforge.net:/home/frs/project/cesiumos-org/"$DEVICE"/
      cat out/target/product/"$DEVICE"/CesiumOS*.zip.json
}

exports
if [ "$SYNC" = "true" ]; then
    sync
    track_private
fi
use_ccache
clean_up
build_main
build_end
