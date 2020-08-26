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

#Set Date and Time
export BUILD_DATE=$(date +%Y%m%d)
export BUILD_TIME=$(date +%H%M)

# Switch to source directory
cd ../
cd corvus

#Remove previous device repo before starting a new build
rm -rf device/*


# Don't start build if gerrit is down
curl --silent --fail --location review.corvusrom.com >/dev/null || {
    sendMessage "$DEVICE $DU_BUILD_TYPE is being aborted because gerrit is down!"
    exit 1
}

# Notify Trigger
sendMessage "Build Triggered on Jenkins for ${DEVICE}-$BUILD_VARIANT "
sendMessage "$(/var/lib/jenkins/workspace/Corvus/jenkins/maintainer.py "$DEVICE")"

# Repo Init
repo init -u https://github.com/Corvus-ROM/android_manifest.git -b 10 --no-tags --no-clone-bundle --current-branch
PARSE_MODE="html" sendMessage "Repo Initialised"

# Repo sync
PARSE_MODE="html" sendMessage "Starting repo sync. Executing command: time repo sync"
time repo sync -j"$(nproc)" --current-branch --no-tags --no-clone-bundle --force-sync

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

source build/envsetup.sh
if [[ -f .repo/local_manifests/local_corvus.xml ]]; then
    rm .repo/local_manifests/local_corvus.xml
fi

#Lunch
set +e
lunch du_"${DEVICE}"-"${BUILD_TYPE}"

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
if mka "$MAKE_TARGET"; then
    sendMessage "${DEVICE} build is done, check [jenkins](${BUILD_URL}) for details!"
    sendMessage "$(/var/lib/jenkins/workspace/Corvus/jenkins/maintainer.py "$DEVICE")"
    sendMessage "Build finished successfully! for ${DEVICE}  Uploading Build"
fi

#Upload to FTP
if [ "$UPLOAD" = "YES" ]; then
    curl  --user  "$REMOTE_USERNAME":"$REMOTE_PASSWORD" --ftp-pasv -T out/target/product/"${DEVICE}"/Corvus_*.zip  ftp://ftp.corvusrom.com/public_html/corvusrom.com/public_html/
    sendMessage "Build Uploaded @ritzz97 send link"
fi

sendMessage "Build Done"
