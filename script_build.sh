#!/bin/bash

# Export some variables
user=corvus
OUT_PATH="out/target/product/${device}"
ROM_ZIP=Corvus_*.zip
folderid=""

ROOMSERVICE_DEFAULT_BRANCH=$rsb

# Colors makes things beautiful
export TERM=xterm

    red=$(tput setaf 1)             #  red
    grn=$(tput setaf 2)             #  green
    blu=$(tput setaf 4)             #  blue
    cya=$(tput setaf 6)             #  cyan
    txtrst=$(tput sgr0)             #  Reset

echo $device > /home/$user/current_device

# Reset trees & Sync with latest source
if [ "${repo_sync}" = "yes" ];
then
repo sync --force-sync --force-remove-dirty --no-tags --no-clone-bundle
echo -e ${grn}"Fresh Sync"${txtrst}
fi

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
export CCACHE_DIR=/home/$user/ccache/${device}
ccache -M 40G
ccache -o compression=true
fi

if [ "${use_ccache}" = "clean" ];
then
export CCACHE_EXEC=$(which ccache)
export CCACHE_DIR=/home/$user/ccache/${device}
ccache -C
export USE_CCACHE=1
ccache -M 40G
ccache -o compression=true
wait
echo -e ${grn}"CCACHE Cleared"${txtrst};
fi

rm -rf ${OUT_PATH}/${ROM_ZIP} #clean rom zip in any case

# Sign corvus builds
if [ "${sign_builds}" = "yes" ];
then
git clone git@github.com:Corvus-R/.certs.git certs
export SIGNING_KEYS=certs
fi

# Ship Official builds
export RAVEN_LAIR=Official

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

if [ "${make_clean}" = "installclean" ];
then
make installclean
wait
echo -e ${cya}"Images deleted from OUT dir"${txtrst};
fi

source build/envsetup.sh
echo "Vanilla" > /home/$user/build_type
make bacon -j$(nproc --all)

export SSHPASS=""

if [ `ls ${OUT_PATH}/${ROM_ZIP} 2>/dev/null | wc -l` != "0" ]; then
RESULT=Success
cd ${OUT_PATH}
RZIP="$(ls ${ROM_ZIP})"

fileid=$(gdrive upload --parent ${folderid} ${RZIP} | tail -1 | awk '{print $2}')
echo "https://drive.google.com/file/d/${fileid}/view?usp=drivesdk" > /home/corvus/vanilla_link

# Make OTA json
name=$(grep ro\.product\.system\.model system/build.prop | cut -d= -f2)
version_codename=$(grep ro\.corvus\.codename system/build.prop | cut -d= -f2)
version=$(grep ro\.corvus\.build\.version system/build.prop | cut -d= -f2)
size=$(stat -c%s $RZIP)
datetime=$(grep ro\.build\.date\.utc system/build.prop | cut -d= -f2)
filehash=$(md5sum $RZIP | awk '{ print $1 }')
maintainer=$(python3 /home/$user/builder/device_data.py ${device} maintainer | sed 's/@//g')
url=$(python3 /home/$user/builder/device_data.py ${device} download)
group=$(python3 /home/$user/builder/device_data.py ${device} tg_support_group)
echo "{" > $device.json
echo "  \"codename\":\"${device}\"," >> $device.json
echo "  \"name\":\"${name}\"," >> $device.json
echo "  \"version_codename\":\"${version_codename}\"," >> $device.json
echo "  \"version\":\"${version}\"," >> $device.json
echo "  \"maintainer\":\"${maintainer}\"," >> $device.json
echo "  \"size\":${size}," >> $device.json
echo "  \"datetime\":${datetime}," >> $device.json
echo "  \"filehash\":\"${filehash}\"," >> $device.json
echo "  \"url\":\"${url}\"," >> $device.json
echo "  \"group\":\"${group}\"" >> $device.json
echo "}" >> $device.json
cp $device.json /home/$user/builder/
cd ../../../../ #fall back to root dir of source

   ~/sshpass -e sftp -oBatchMode=no -b - user@frs.thunderserver.in << !
     cd /ravi
     put $RZIP
     put /home/$user/builder/$device.json
     bye
!

else
exit 1
fi

# If vanilla build is compiled let's compile gapps now
if [ "${RESULT}" = "Success" ];
then
export USE_GAPPS=true
rm -rf ${OUT_PATH}/${ROM_ZIP} #clean rom zip in any case
echo "Gapps" > /home/$user/build_type
source build/envsetup.sh
lunch corvus_"${device}"-"${build_type}"
make installclean
if ! make bacon -j$(nproc --all); then
  exit 1
fi

cd ${OUT_PATH}
RZIP="$(ls ${ROM_ZIP})"

fileid=$(gdrive upload --parent ${folderid} ${RZIP} | tail -1 | awk '{print $2}')
echo "https://drive.google.com/file/d/${fileid}/view?usp=drivesdk" > /home/$user/gapps_link

   ~/sshpass -e sftp -oBatchMode=no -b - user@frs.thunderserver.in << !
     cd /ravi
     put $RZIP
     bye
!
else
exit 1
fi
