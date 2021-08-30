#!/bin/bash

# Colors makes things beautiful
export TERM=xterm

    red=$(tput setaf 1)             #  red
    grn=$(tput setaf 2)             #  green
    blu=$(tput setaf 4)             #  blue
    cya=$(tput setaf 6)             #  cyan
    txtrst=$(tput sgr0)             #  Reset

echo $device > /home/corvus/device

# Sync with latest source
if [ "${repo_sync}" = "yes" ];
then
repo sync --force-sync --force-remove-dirty --no-tags --no-clone-bundle
echo -e ${grn}"Fresh Sync"${txtrst}
fi

# Reset trees & sync with latest source
if [ "${repo_sync}" = "clean" ];
then
rm -rf .repo/local_manifests
repo sync --force-sync --force-remove-dirty --no-tags --no-clone-bundle
echo -e ${grn}"Cleaned existing device repos"${txtrst}
fi

# Ccache
if [ "${use_ccache}" = "yes" ];
then
echo -e ${blu}"CCACHE is enabled for this build"${txtrst}
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_DIR=/home/corvus/ccache/${device}
ccache -M 40G
ccache -o compression=true
fi

if [ "${use_ccache}" = "clean" ];
then
export CCACHE_EXEC=$(which ccache)
export CCACHE_DIR=/home/corvus/ccache/${device}
ccache -C
export USE_CCACHE=1
ccache -M 40G
ccache -o compression=true
wait
echo -e ${grn}"CCACHE Cleared"${txtrst};
fi

rm -rf out/target/product/${device}/Corvus_*.zip #clean rom zip in any case

# Sign corvus builds
if [ "${sign_builds}" = "yes" ]:
then
git clone git@github.com:Corvus-R/.certs.git certs
export SIGNING_KEYS=certs
fi

# Ship Official builds
export RAVEN_LAIR=Official

# Make a vanilla build first
export USE_GAPPS=false

# Time to build
source build/envsetup.sh

if ! lunch corvus_"${device}"-"${build_type}"; then
  exit 1
fi

# Make clean
if [ "${make_clean}" = "yes" ];
then
make clean
wait
echo -e ${cya}"OUT dir from your repo deleted"${txtrst};
fi

# Make Installclean
if [ "${make_clean}" = "installclean" ];
then
make installclean
wait
echo -e ${cya}"Images deleted from OUT dir"${txtrst};
fi

echo "Vanilla" > /home/corvus/build_type
make bacon -j$(nproc --all)

if [ `ls out/target/product/${device}/Corvus_*.zip 2>/dev/null | wc -l` != "0" ]; then
RESULT=Success
cd out/target/product/${device}
RZIP="$(ls Corvus_*.zip)"

fileid=$(gdrive upload --parent 1G5d_sY6GsKIIBrvPac5K_jpTRL2p74dE ${RZIP} | tail -1 | awk '{print $2}')
echo "https://drive.google.com/file/d/${fileid}/view?usp=drivesdk" > /home/corvus/vanilla_link

cd ../../../../ #fall back to root dir of source
else
exit 1
fi

# If vanilla build is compiled let's compile gapps now
if [ "${RESULT}" = "Success" ];
then
export USE_GAPPS=true
rm -rf out/target/product/${device}/Corvus_*.zip #clean rom zip in any case
echo "Gapps" > /home/corvus/build_type
source build/envsetup.sh
lunch corvus_"${device}"-"${build_type}"
make installclean
if ! make bacon -j$(nproc --all); then
  exit 1
fi

cd out/target/product/${device}
RZIP="$(ls out/target/product/${device}/Corvus_*.zip)"
fileid=$(gdrive upload --parent 1G5d_sY6GsKIIBrvPac5K_jpTRL2p74dE ${RZIP} | tail -1 | awk '{print $2}')
echo "https://drive.google.com/file/d/${fileid}/view?usp=drivesdk" > /home/corvus/gapps_link
else
exit 1
fi
