#!/usr/bin/env bash

# Copyright (C) 2020 Ayush Dubey
# SPDX-License-Identifier: GPL-3.0-only
# Corvus build script
# shellcheck disable=SC1091
# SC1091: Not following: (error message here)
# SC2153: Possible Misspelling: MYVARIABLE may not be assigned, but MY_VARIABLE is.
# SC2155: Declare and assign separately to avoid masking return values

export TZ=UTC

sendMessage() {
    MESSAGE=$1
    curl -s "https://api.telegram.org/bot${BOT_API_KEY}/sendmessage" --data "text=$MESSAGE&chat_id=-1001130083853" 1>/dev/null
    echo -e
}

# Set defaults
MAKE_TARGET="corvus"

#Set Date and Time
export BUILD_DATE=$(date +%Y%m%d)
export BUILD_TIME=$(date +%H%M)

# Switch to source directory
cd ../
cd corvus

# Don't start build if gerrit is down
curl --silent --fail --location review.corvusrom.com >/dev/null || {
    sendMessage "$DEVICE $DU_BUILD_TYPE is being aborted because gerrit is down!"
    exit 1
}

# Notify Trigger
sendMessage "Build Triggered on Jenkins for ${DEVICE}-$BUILD_VARIANT "
sendMessage "$(/var/lib/jenkins/workspace/Corvus/jenkins/maintainer.py "$DEVICE")"

# Repo Init
repo init -u https://github.com/Corvus-R/android_manifest.git -b 11-ssh --no-tags --no-clone-bundle --current-branch
PARSE_MODE="html" sendMessage "Repo Initialised"

#Cleanup local manifest
source build/envsetup.sh
if [[ -f .repo/local_manifests/local_corvus.xml ]]; then
    rm .repo/local_manifests/local_corvus.xml
fi

# Repo sync
PARSE_MODE="html" sendMessage "Starting repo sync. Executing command:  repo sync"
repo forall --ignore-missing -j"$(nproc)" -c "git reset --hard m/10 && git clean -fdx"
time repo sync -j"$(nproc)" --current-branch --no-tags --no-clone-bundle --force-sync

# Clone Vendor 
git clone git@github.com:Corvus-R/vendor_corvus.git vendor/corvus

# Build Variant
if [ "$BUILD_VARIANT" = "gapps" ]; then
    export USE_GAPPS=true
else
    export USE_GAPPS=false
fi

# Build Type
if [ "$RAVEN_LAIR" = "Official" ]; then
    export RAVEN_LAIR=Official
    git clone git@github.com:Corvus-R/.certs .certs
    export SIGNING_KEYS=.certs
else
    export RAVEN_LAIR=Unofficial
fi

# Build
set -e
export PATH=~/bin:$PATH
sendMessage "Starting ${DEVICE}-${RAVEN_LAIR}-${BUILD_DATE}-${BUILD_TIME}  build, check progress here ${BUILD_URL}"

#Envsetup
source build/envsetup.sh

#Lunch
set +e
lunch corvus_"${DEVICE}"-"${BUILD_TYPE}"
#call vendorsetup.sh after cloning the device, for including device specific patches
source build/envsetup.sh

set -e

# Clean
if [[ ${CLEAN} =~ ^(clean|deviceclean|installclean)$ ]]; then
    m "${CLEAN}"
else
    rm -rf "${OUT}"*
fi

set -e

# Cache
export CCACHE_EXEC="$(command -v ccache)"
export USE_CCACHE=1
ccache -M 75G
export _JAVA_OPTIONS=-Xmx16g
export SKIP_ABI_CHECKS=true
if mka "$MAKE_TARGET"; then
    sendMessage "${DEVICE} build is done, check jenkins (${BUILD_URL}) for details!"
    sendMessage "$(/var/lib/jenkins/workspace/Corvus/jenkins/maintainer.py "$DEVICE")"
    sendMessage "Build finished successfully! for ${DEVICE}  Uploading Build"
fi

#Upload to FTP
if [ "$UPLOAD" = "YES" ]; then
    sendMessage "Uploading Build to  Osdn"
    scp -r out/target/product/"${DEVICE}"/Corvus_* corvusos@storage.osdn.net:/storage/groups/c/co/corvusos/"${DEVICE}"
fi

# Remove Vendor 
rm -rf vendor/corvus
if [ "$RAVEN_LAIR" = "Official" ]; then
      rm -rf .certs
      sendMessage "Build Done"
else
      sendMessage "Build Done"
fi
