##########################################################
# Copyright [2016] [Chris Holman@Awltux Ltd]
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################


########################################################
# Install virtualbox guest additions; as per...
# https://www.vagrantup.com/docs/virtualbox/boxes.html
########################################################
CENTOS_MAJ_VER=$(sed -rn 's/[a-zA-Z ]+([0-9])\.[0-9].*/\1/p' /etc/redhat-release)
DOWNLOAD_DIR=$(pwd)/downloads
echo "DOWNLOAD_DIR=${DOWNLOAD_DIR}"

INSTALL_DIR=${DOWNLOAD_DIR}/install
UPDATE_DIR=${DOWNLOAD_DIR}/update

EPEL_RPM_FILENAME=epel-release-${CENTOS_MAJ_VER}-*.noarch.rpm
EPEL_RPM_DOWNLOAD=${INSTALL_DIR}/${EPEL_RPM_FILENAME}

###################################################
# INSTALL EPEL yum repo metadata
if $ONLINE ; then
  echo "Install 'wget' to pull RPM packages from internet"
  yum --assumeyes --nogpgcheck install wget || (RC=$? && echo "RC=$RC" && exit $RC )
  echo "Downloading EPEL repository RPM"
  echo "http://dl.fedoraproject.org/pub/epel/${CENTOS_MAJ_VER}/x86_64/e/${EPEL_RPM_FILENAME}"
  wget -r --no-parent -P ${INSTALL_DIR} -q --no-directories --accept="${EPEL_RPM_FILENAME}" http://dl.fedoraproject.org/pub/epel/${CENTOS_MAJ_VER}/x86_64/e/ || (RC=$? && echo "RC=$RC" && exit $RC )
fi

# Check that the file is available on disk.
if [ ! -f ${EPEL_RPM_DOWNLOAD} ]; then
  echo "RPM not found: ${EPEL_RPM_DOWNLOAD}"
  exit 1
fi

echo "OFFLINE INSTALL OF EPEL REOPOSITORY CONFIG"
yum --assumeyes -q localinstall ${EPEL_RPM_DOWNLOAD} || (RC=$? && echo "RC=$RC" && exit $RC )

###################################################
# Fetch updated RPMs. To pick up an security fixes
if $ONLINE ; then
  echo "Update RPM packages from internet"
  echo "IMPORTANT NOTE: Exclude all kernel related upgrades as configuring bootloader is awkward to automate"
  yum --downloadonly --downloaddir=${UPDATE_DIR} --assumeyes --nogpgcheck --exclude *kernel-* update  || (RC=$? && echo "RC=$RC" && exit $RC )
fi

# OFFLINE UPDATE. WARNING: this is relative to the currnent centos/7 vagrant box version (which is constantly being patched)
if [ -f "${UPDATE_DIR}/*.rpm" ]; then
  yum --assumeyes -q localinstall ${UPDATE_DIR}/*.rpm || (RC=$? && echo "RC=$RC" && exit $RC )
fi

###################################################
# INSTALL VIRTUALBOX GUEST ADDITIONS
if $ONLINE ; then
  echo "DOWNLOAD DEV TOOLS for VBOX guest additions (removed after install)"
  yum --downloadonly --downloaddir=${INSTALL_DIR} --assumeyes --nogpgcheck -q install policycoreutils-python kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc gcc-c++ make openssl-devel dkms  || (RC=$? && echo "RC=$RC" && exit $RC )
fi

echo "OFFLINE INSTALL OF DEV TOOLS"
yum --assumeyes -q localinstall ${INSTALL_DIR}/*.rpm  || (RC=$? && echo "RC=$RC" && exit $RC )
  
VBOX_GUEST_ADDITIONS_ISO_NAME=VBoxGuestAdditions_${VBOX_VERSION}.iso
VBOX_GUEST_ADDITIONS_ISO_URL=http://download.virtualbox.org/virtualbox/${VBOX_VERSION}/${VBOX_GUEST_ADDITIONS_ISO_NAME}
VBOX_GUEST_ADDITIONS_ISO_DOWNLOAD=${INSTALL_DIR}/${VBOX_GUEST_ADDITIONS_ISO_NAME}

echo "Downloading VBOX Guest additions from:"
echo "   ${VBOX_GUEST_ADDITIONS_ISO_URL}"
wget -P ${INSTALL_DIR} -q ${VBOX_GUEST_ADDITIONS_ISO_URL} || (RC=$? && echo "RC=$RC" && exit $RC )
mkdir /media/VBoxGuestAdditions  || (RC=$? && echo "RC=$RC" && exit $RC )
mount -o loop,ro ${VBOX_GUEST_ADDITIONS_ISO_DOWNLOAD} /media/VBoxGuestAdditions  || exit $?

sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
echo "VBoxLinuxAdditions.run: RC=$?"

echo "########################################################"
echo "Scrub VBoxGuestAdditions install files"
umount /media/VBoxGuestAdditions  || (RC=$? && echo "RC=$RC" && exit $RC )
rmdir /media/VBoxGuestAdditions  || (RC=$? && echo "RC=$RC" && exit $RC )

echo "Remove development packages"
yum --assumeyes erase wget gcc gcc-c++ openssl-devel dkms perl cpp kernel-headers-$(uname -r) kernel-devel-$(uname -r)  || (RC=$? && echo "RC=$RC" && exit $RC )

if $CLEAN_DOWNLOADS ; then
  echo "Clean up downloaded files"
  rm -rf ${INSTALL_DIR}  || (RC=$? && echo "RC=$RC" && exit $RC )
fi

echo "Scrub excess packages and drive space from the VBox"
  yum clean all  || (RC=$? && echo "RC=$RC" && exit $RC )

# Fill all available drive space and then delete it. Makes box smaller.
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# empty out the history files
cat /dev/null > ~/.bash_history && history -c    
