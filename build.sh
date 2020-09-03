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
    curl -s "https://api.telegram.org/bot${BOT_API_KEY}/sendmessage" --data "text=$MESSAGE&chat_id=-1001179187393" 1>/dev/null
    echo -e
}

# Set defaults
MAKE_TARGET="corvus"

# Lets Make Terminal Colorful
export TERM=xterm
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
blu=$(tput setaf 4)             #  blue
cya=$(tput setaf 6)             #  cyan
txtrst=$(tput sgr0)             #  Reset

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
git config --global user.name "riteshm321" 
git config --global user.email "riteshm321@gmail.com"
echo -e ${blu} "[*] Syncing sources Gonna take while" ${txtrst}
repo init -u https://github.com/Corvus-ROM/android_manifest.git -b 10 --no-tags --no-clone-bundle --current-branch
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

echo -e ${cya} "[*] Syncing sources completed!" ${txtrst}
# Build Variant
if [ "$BUILD_VARIANT" = "gapps" ]; then
    export USE_GAPPS=true
else
    export USE_GAPPS=false
fi

# Face Unlock
if [[ ! -f external/motorola/faceunlock/regenerate/regenerate.sh ]]; then
    git clone git@github.com:Corvus-ROM/android_external_motorola_faceunlock.git external/motorola/faceunlock && bash external/motorola/faceunlock/regenerate/regenerate.sh
else
    . external/motorola/faceunlock/regenerate/regenerate.sh
fi

# Build Type
if [ "$DU_BUILD_TYPE" = "Official" ]; then
    export DU_BUILD_TYPE=Official
else
    export DU_BUILD_TYPE=Unofficial
fi

# Build
set -e
export PATH=~/bin:$PATH
sendMessage "Starting ${DEVICE}-${DU_BUILD_TYPE}-${BUILD_DATE}-${BUILD_TIME}  build, check progress here ${BUILD_URL}"

#Envsetup
source build/envsetup.sh

#Lunch
set +e
lunch du_"${DEVICE}"-"${BUILD_TYPE}"
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
export CCACHE_DIR=/var/lib/jenkins/workspace/Corvus/.ccache
ccache -M 500G
export _JAVA_OPTIONS=-Xmx16g
echo -e ${blu} "[*] ccache important decrease time!" ${txtrst}
echo -e ${blu}"[*] Starting the build" ${txtrst}
if mka "$MAKE_TARGET"; then
    sendMessage "${DEVICE} build is done, check jenkins (${BUILD_URL}) for details!"
    sendMessage "$(/var/lib/jenkins/workspace/Corvus/jenkins/maintainer.py "$DEVICE")"
    sendMessage "Build finished successfully! for ${DEVICE}  Uploading Build"
fi

#Upload to FTP
if [ "$UPLOAD" = "YES" ]; then
    sendMessage "Uploading Build to  Osdn"
    scp -r out/target/product/"${DEVICE}"/Corvus_* corvusos@storage.osdn.net:/storage/groups/c/co/corvusos/"${DEVICE}"
    sendMessage "Moving  Build to h5ai"
    mv out/target/product/"${DEVICE}"/Corvus_*.zip ~/Builds/"$DEVICE"/
    sendMessage "Build Uploaded @ritzz97 send pling  link xD"
fi

sendMessage "Build Done"
