# -*- mode: ruby -*-
# vi: set ft=ruby :

##########################################################
# VAGRANT INSTALLS THE MINIMUM AMOUNT TO GET:
#   * BASE INFRASTRUCTURE
#   * VAGRANT USER SSH CERTS TO ALLOW PASSWORDLESS LOGIN
#   * VIRTUALBOX guest additions
# Ansible should be used to install the system. As this 
# can also be used on physical systems, not just Vagrant
##########################################################
# OFFLINE=1 assumes that you are updating against an idempotent repository i.e. OpticalDisk
# OFFLINE=0 # update can bring in a new version of the kernel.
OFFLINE=0

CLEAN_DOWNLOADS=0

require "ipaddr"

class VagrantConfigMissing < StandardError
end

vagrant_dir = File.expand_path(File.dirname(__FILE__))

# Get the version of installed Vbox using "vboxmanage -v". 
#Only use the three version places.
##########################################################
# TODO: automate these version parameters
##########################################################
VBOX_VERSION = "5.1.2"
CENTOS_MAJ_VER=7

# Vagrantfile.custom contains user customization for the Vagrantfile
# You shouldn't have to edit the Vagrantfile, ever.
if File.exists?(File.join(vagrant_dir, 'Vagrantfile.custom'))
  eval(IO.read(File.join(vagrant_dir, 'Vagrantfile.custom')), binding)
end

# Either libvirt or virtualbox
PROVIDER ||= "virtualbox"
# Either centos or ubuntu
DISTRO ||= "centos"

# The libvirt graphics_ip used for each guest. Only applies if PROVIDER
# is libvirt.
GRAPHICSIP ||= "127.0.0.1"

# The bootstrap.sh provision_script requires CentOS 7 or Ubuntu 15.10.
# Provisioning other boxes than the default ones may therefore
# require changes to bootstrap.sh.
PROVISION_SCRIPT ||= "bootstrap.sh"

PROVIDER_DEFAULTS ||= {
  libvirt: {
    centos: {
      base_image: "centos/7",
      bridge_interface: "virbr0",
      vagrant_shared_folder: "/home/vagrant/sync",
    }
  },
  virtualbox: {
    centos: {
      base_image: "centos/7",
      bridge_interface: "wlp3s0b1",
      vagrant_shared_folder: "/home/vagrant/sync",
    }
  }
}

# Whether the host network adapter is Wi-Fi.
# On VirtualBox, the user must first manually create a NAT-Network
# named "OSNetwork". The default network CIDR must be changed.
# The Neutron external interface will be connected to this Network.
WIFI = false unless self.class.const_defined?(:WIFI)


NODE_SETTINGS ||= {
  vboxbase: {
    cpus: 3,
    memory: 2048
  }
}

if PROVIDER == "virtualbox" 
  system("vboxmanage -v>vbox_version.out")
    
end



def get_default(setting)
  PROVIDER_DEFAULTS[PROVIDER.to_sym][DISTRO.to_sym][setting]
rescue
  raise VagrantConfigMissing,
    "Missing configuration for PROVIDER_DEFAULTS[#{PROVIDER}][#{DISTRO}][#{setting}]"
end

def get_setting(node, setting)
  NODE_SETTINGS[node][setting]
rescue
  raise VagrantConfigMissing,
    "Missing configuration for NODE_SETTINGS[#{node}][#{setting}]"
end

def configure_wifi_vbox_networking(vm)
  # Even if adapters 1 & 2 don't need to be modified, if the order is to be
  # maintained, some modification has to be done to them. This will maintain
  # the association inside the guest OS: NIC1 -> eth0, NIC2 -> eth1, NIC3 ->
  # eht2. The modifications for adapters 1 & 2 only change optional properties.
  # Adapter 3 is enabled and connected to the NAT-Network named "OSNetwork",
  # while also changing its optional properties. Since adapter 3 is used by
  # Neutron for the external network, promiscuous mode is set to "allow-all".
  # Also, use virtio as the adapter type, for better performance.
  vm.customize ["modifyvm", :id, "--nictype1", "virtio"]
  vm.customize ["modifyvm", :id, "--cableconnected1", "on"]
  vm.customize ["modifyvm", :id, "--nicpromisc2", "deny"]
  vm.customize ["modifyvm", :id, "--nictype2", "virtio"]
  vm.customize ["modifyvm", :id, "--cableconnected2", "on"]
  vm.customize ["modifyvm", :id, "--nic3", "natnetwork"]
  vm.customize ["modifyvm", :id, "--nat-network3", "OSNetwork"]
  vm.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
  vm.customize ["modifyvm", :id, "--nictype3", "virtio"]
  vm.customize ["modifyvm", :id, "--cableconnected3", "on"]
end

def configure_wifi_if_enabled(vm)
  if WIFI
    case PROVIDER
    when "virtualbox"
      configure_wifi_vbox_networking(vm)
#   TODO(lucian-serb): Configure networking on Wi-Fi for other hypervisors.
#   when "libvirt"
#     configure_wifi_libvirt_networking(vm)
    end
  end
end

Vagrant.configure(2) do |config|
  config.vm.box = get_default(:base_image)
  config.ssh.insert_key = false
#  config.ssh.username = bootstrap
#  config.ssh.password = bootstrap
  
  # Next to the hostonly NAT-network there is a host-only network with all
  # nodes attached. Plus, each node receives a 3rd adapter connected to the
  # outside public network.
  config.vm.network "private_network", type: "dhcp"

  # On VirtualBox hosts with Wi-Fi, do not create a public bridged interface.
  # A NAT-Network will be used instead.
  # TODO(lucian-serb): Do the same for other hypervisors as well?
  unless PROVIDER == "virtualbox" && WIFI
    config.vm.network "public_network", dev: get_default(:bridge_interface), mode: 'bridge', type: 'bridge'
  end

  config.vm.provision :shell, inline: <<-EOS
    ########################################################
    # Install virtualbox guest additions; as per...
    # https://www.vagrantup.com/docs/virtualbox/boxes.html
    ########################################################
    #CENTOS_MAJ_VER=$(sed -rn 's/[a-zA-Z ]+([0-9])\.[0-9].*/\1/p' /etc/redhat-release)
    DOWNLOAD_DIR=$(pwd)/downloads
    UPDATE_DIR=$(pwd)/downloads/update
    echo "DOWNLOAD_DIR=${DOWNLOAD_DIR}"
    
    EPEL_RPM_FILENAME=epel-release-#{CENTOS_MAJ_VER}-*.noarch.rpm
    EPEL_RPM_DOWNLOAD=${DOWNLOAD_DIR}/${EPEL_RPM_FILENAME}
   
    ###################################################
    # INSTALL EPEL yum repo metadata
    if $ONLINE ; then
      echo "Install 'wget' to pull RPM packages from internet"
      yum --assumeyes --nogpgcheck install wget || (RC=$? && echo "RC=$RC" && exit $RC )
      echo "Downloading EPEL repository RPM"
      echo "http://dl.fedoraproject.org/pub/epel/#{CENTOS_MAJ_VER}/x86_64/e/${EPEL_RPM_FILENAME}"
      wget -r --no-parent -P ${DOWNLOAD_DIR} -q --no-directories --accept="${EPEL_RPM_FILENAME}" http://dl.fedoraproject.org/pub/epel/#{CENTOS_MAJ_VER}/x86_64/e/ || (RC=$? && echo "RC=$RC" && exit $RC )
    fi
    
    # Check that the file is available on disk.
    if [ ! -f ${EPEL_RPM_DOWNLOAD} ]; then
      echo "RPM not found: ${EPEL_RPM_DOWNLOAD}"
      exit 1
    fi
    
    echo "OFFLINE INSTALL OF EPEL REOPOSITORY CONFIG"
    yum --assumeyes localinstall ${EPEL_RPM_DOWNLOAD} || (RC=$? && echo "RC=$RC" && exit $RC )

    ###################################################
    # Fetch updated RPMs. To pick up an security fixes
    if $ONLINE ; then
      echo "Update RPM packages from internet"
      echo "IMPORTANT NOTE: Exclude all kernel related upgrades as configuring bootloader is awkward to automate"
      yum --downloadonly --downloaddir=${UPDATE_DIR} --assumeyes --nogpgcheck --exclude *kernel-* update  || (RC=$? && echo "RC=$RC" && exit $RC )
    fi

    # OFFLINE UPDATE. WARNING: this is relative to the currnent centos/7 vagrant box version (which is constantly being patched)
    if [ -f "${UPDATE_DIR}/*.rpm" ]; then
      yum --assumeyes localinstall ${UPDATE_DIR}/*.rpm || (RC=$? && echo "RC=$RC" && exit $RC )
    fi
    
    ###################################################
    # INSTALL VIRTUALBOX GUEST ADDITIONS
    if $ONLINE ; then
      echo "DOWNLOAD DEV TOOLS for VBOX guest additions (removed after install)"
      yum --downloadonly --downloaddir=${DOWNLOAD_DIR} --assumeyes --nogpgcheck install policycoreutils-python kernel-headers-$(uname -r) gcc gcc-c++ make openssl-devel dkms  || (RC=$? && echo "RC=$RC" && exit $RC )
    fi

    echo "OFFLINE INSTALL OF DEV TOOLS"
    yum --assumeyes localinstall ${DOWNLOAD_DIR}/*.rpm  || (RC=$? && echo "RC=$RC" && exit $RC )
      
    VBOX_GUEST_ADDITIONS_ISO_NAME=VBoxGuestAdditions_#{VBOX_VERSION}.iso
    VBOX_GUEST_ADDITIONS_ISO_URL=http://download.virtualbox.org/virtualbox/#{VBOX_VERSION}/${VBOX_GUEST_ADDITIONS_ISO_NAME}
    VBOX_GUEST_ADDITIONS_ISO_DOWNLOAD=${DOWNLOAD_DIR}/${VBOX_GUEST_ADDITIONS_ISO_NAME}

    echo "Downloading VBOX Guest additions from:"
    echo "   ${VBOX_GUEST_ADDITIONS_ISO_URL}"
    wget -P ${DOWNLOAD_DIR} -q ${VBOX_GUEST_ADDITIONS_ISO_URL} || (RC=$? && echo "RC=$RC" && exit $RC )
    mkdir /media/VBoxGuestAdditions  || (RC=$? && echo "RC=$RC" && exit $RC )
    mount -o loop,ro ${VBOX_GUEST_ADDITIONS_ISO_DOWNLOAD} /media/VBoxGuestAdditions  || exit $?
    
    sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
    echo "VBoxLinuxAdditions.run: RC=$?"
 
    echo "########################################################"
    echo "Scrub VBoxGuestAdditions install files"
#    umount /media/VBoxGuestAdditions  || (RC=$? && echo "RC=$RC" && exit $RC )
#    rmdir /media/VBoxGuestAdditions  || (RC=$? && echo "RC=$RC" && exit $RC )

    echo "Remove development packages"
#    yum --assumeyes erase wget gcc gcc-c++ openssl-devel dkms perl cpp kernel-headers-$(uname -r)  || (RC=$? && echo "RC=$RC" && exit $RC )

    if $CLEAN_DOWNLOADS ; then
      echo "Clean up downloaded files"
    #  rm -rf ${DOWNLOAD_DIR}  || (RC=$? && echo "RC=$RC" && exit $RC )
    fi
  
    echo "Scrub excess packages and drive space from the VBox"
    #  yum clean all  || (RC=$? && echo "RC=$RC" && exit $RC )
    
    # Fill all available drive space and then delete it. Makes box smaller.
    dd if=/dev/zero of=/EMPTY bs=1M
    rm -f /EMPTY
    
    # empty out the history files
    cat /dev/null > ~/.bash_history && history -c    
EOS

  config.hostmanager.enabled = true

  # Make sure hostmanager picks IP address of eth1
  # The operator controls the rest of the deploy
  config.vm.define "vboxcentos7" do |vboxcentos7|
    vboxcentos7.vm.hostname = "vboxcentos7.local"

    # VBoxGuestAdditions not installed yet. disable for this run
    vboxcentos7.vm.synced_folder ".", get_default(:vagrant_shared_folder), disabled: true
  end

end
