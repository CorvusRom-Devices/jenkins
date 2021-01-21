#!/bin/bash

# Colors makes things beautiful
export TERM=xterm
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
blu=$(tput setaf 4)             #  blue
cya=$(tput setaf 6)             #  cyan
txtrst=$(tput sgr0)             #  Reset

sendMessage() {
    MESSAGE=$1
    curl -s "https://api.telegram.org/bot${BOT_API_KEY}/sendmessage" --data "text=$MESSAGE&chat_id=-1001130083853" 1>/dev/null
    echo -e
}

function certs() {
  echo "Unzipping certs!"
  echo "$SIGNING_KEYS_ZIP"
  unzip -jo $SIGNING_KEYS_ZIP "certs/*" -d .certs;
  export SIGNING_KEYS=.certs;
  errcode=$?
  if [ ! $errcode -eq 0 ]; then
	  echo -e ${red}"[!] Failed to extract signing certs!"${txtrst};
	  exit $errcode;
  fi
}
if [ $SYNC = yes ]; then
rm -rf *

fi

if [ "$RAVEN_LAIR" = "Official" ]; then
  export RAVEN_LAIR=Official
  certs
else
  export RAVEN_LAIR=unoffical
fi

if [ ! -f ~/.ssh/config ]; then
  mkdir -p ~/.ssh && echo "Host *" > ~/.ssh/config && \
  	echo " StrictHostKeyChecking no" >> ~/.ssh/config;
  chmod 400 ~/.ssh/config    
fi

# Notify Trigger
sendMessage "$DEVICE 69TH BUILD STARTED GAPPS OR NON GAPPS WHO CARES";

# For repo to work, define git user; preferably bot
git config --global user.email "singhalaashil@gmail.com"
git config --global user.name "aashil123"

# Setup ccache
  export USE_CCACHE=1
  echo -e ${blu}"[*] CCACHE ENABLED"${txtrst}
  ccache -M 200G

# Let's get syncing!
  echo -e ${blu}"[*] Initializing repo"${txtrst};
  repo init -u https://github.com/Corvus-R/android_manifest -b 11 2> /dev/null;
  PARSE_MODE="html" sendMessage "Repo Initialised";
  rm -rf .repo/local_manifests;
  repo forall --ignore-missing -j"$(nproc)" -c "git reset --hard m/11 && git clean -fdx"
  echo -e ${blu}"[*] Syncing sources..."${txtrst};
  PARSE_MODE="html" sendMessage "Starting repo sync. Executing command:  repo sync";
  repo sync -j$(nproc --all) --force-sync --no-tags --no-clone-bundle
# Clone Vendor 
  GIT_SSH_COMMAND='ssh -i $SSH_PRIV_KEY_FILE -o IdentitiesOnly=yes' git clone git@github.com:Corvus-R/vendor_corvus.git vendor/corvus;
  echo -e ${cya}"[*] Sync complete!"${txtrst};

# Prepare for cleanup
source build/envsetup.sh;

# Cleanup
if [ "$clean" = "yes" ]; then
  echo -e ${blu}"[*] Running clean job - full"${txtrst};
  make clean && make clobber
  echo -e ${grn}"[*] clean job complete"${txtrst};
else
  echo -e ${blu}"[*] Running clean job - install"${txtrst};
  make installclean
  echo -e ${cya}"[*] make installclean complete"${txtrst};
fi

# Build Variant
if [ "$BUILD_VARIANT" = "gapps" ]; then
    export USE_GAPPS=true
else
    export USE_GAPPS=false
fi

# Prepare device sources and build env
lunch corvus_"${DEVICE}"-"${BUILD_TYPE}"
source build/envsetup.sh;

# Build ROM
echo -e ${blu}"[*] Starting build..."${txtrst};
sendMessage "Starting ${DEVICE}-${RAVEN_LAIR}-${BUILD_DATE}-${BUILD_TIME}  build, check progress here ${BUILD_URL}";
mka corvus;
build=$(ls -t ${OUT}/Corvus_* | sed -n 2p);
build_name=$(echo $build | rev | cut -d \/ -f 1 | rev);


if [ $? -eq 0 ]; then
  sendMessage "Build Done"
  sendMessage "Ritzz, wen u free, give pling link and post on channel"
  else
  sendMessage "Build Failed";
fi
  
if [ "$UPLOAD" = "OSDN" ]; then
    echo -e ${blu}"[*] Uploading build..."${txtrst};
    sendMessage "Build Will Be available here in few mins for testing only https://osdn.net/projects/corvusos/storage/$DEVICE/$build_name"
    rsync -e "ssh -o StrictHostKeyChecking=no -i $SSH_PRIV_KEY_FILE" out/target/product/"${DEVICE}"/Corvus_* corvusos@storage.osdn.net:/storage/groups/c/co/corvusos/"${DEVICE}"/  
fi

if [ "$UPLOAD" = "SF" ]; then
    echo -e ${blu}"[*] Uploading build..."${txtrst};
    sendMessage "Build Will Be available here in few mins for testing only https://osdn.net/projects/corvusos/storage/$DEVICE/$build_name"
    rsync -azP -e ssh out/target/product/"$DEVICE"/Corvus* merser2005@frs.sourceforge.net:/home/frs/project/corvus-os/"$DEVICE"/
fi

echo -e ${grn}"[*] Removing Private Repos"${txtrst};
rm -rf .certs;
rm -rf vendor/corvus;
