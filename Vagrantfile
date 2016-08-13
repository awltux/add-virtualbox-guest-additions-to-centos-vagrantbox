# -*- mode: ruby -*-
# vi: set ft=ruby :

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

##########################################################
# VAGRANT INSTALLS THE MINIMUM AMOUNT TO GET:
#   * BASE INFRASTRUCTURE
#   * VAGRANT USER SSH CERTS TO ALLOW PASSWORDLESS LOGIN
#   * VIRTUALBOX guest additions
# Ansible should be used to install the system. As this 
# can also be used on physical systems, not just Vagrant
##########################################################

# OFFLINE=1  #assumes that you are updating without network access (requires prep: see README.md)
# OFFLINE=0  #update can bring in a new version of the kernel.
OFFLINE||=0

CLEAN_DOWNLOADS||=0

require "ipaddr"

class VagrantConfigMissing < StandardError
end

vagrant_dir = File.expand_path(File.dirname(__FILE__))

# Get the version of installed Vbox using "vboxmanage -v". 
#Only use the three version places.
##########################################################
# TODO: automate these version parameters
##########################################################

CENTOS_MAJ_VER||="7"

# Either libvirt or virtualbox
PROVIDER ||= "virtualbox"

if PROVIDER == "virtualbox" 
  # TODO: Do some magic to extract VBOX_VERSION from this command
  system("vboxmanage -v>vbox_version.out")
  VBOX_VERSION ||= "5.1.2"
end


# Vagrantfile.custom contains user customization for the Vagrantfile
# You shouldn't have to edit the Vagrantfile, ever.
if File.exists?(File.join(vagrant_dir, 'Vagrantfile.custom'))
  eval(IO.read(File.join(vagrant_dir, 'Vagrantfile.custom')), binding)
end

# Either centos or ubuntu
DISTRO ||= "centos"

# The bootstrap.sh provision_script requires CentOS 7
# Provisioning other boxes than the default ones may therefore
# require changes to bootstrap.sh.
PROVISION_SCRIPT ||= "bootstrap.sh"

PROVIDER_DEFAULTS ||= {
  libvirt: {
    centos: {
      base_image: "centos/#{CENTOS_MAJ_VER}",
      bridge_interface: "virbr0",
      vagrant_shared_folder: "/home/vagrant/sync",
    }
  },
  virtualbox: {
    centos: {
      base_image: "centos/#{CENTOS_MAJ_VER}",
      bridge_interface: "wlp3s0b1",
      vagrant_shared_folder: "/home/vagrant/sync",
    }
  }
}



NODE_SETTINGS ||= {
  vboxbase: {
    cpus: 3,
    memory: 2048
  }
}

def get_default(setting)
  PROVIDER_DEFAULTS[PROVIDER.to_sym][DISTRO.to_sym][setting]
rescue
  raise VagrantConfigMissing,
    "Missing configuration for PROVIDER_DEFAULTS[#{PROVIDER}][#{DISTRO}][#{setting}]"
end


Vagrant.configure(2) do |config|
  config.vm.box = get_default(:base_image)
  config.ssh.insert_key = false
#  config.ssh.username="bootstrap"
#  config.ssh.password="bootstrap"
  
  # Next to the hostonly NAT-network there is a host-only network with all
  # nodes attached. Plus, each node receives a 3rd adapter connected to the
  # outside public network.
  config.vm.network "private_network", type: "dhcp"
  config.vm.network "public_network", dev: get_default(:bridge_interface), mode: 'bridge', type: 'bridge'

  config.vm.provision :shell do |sh|
    sh.path = "#{PROVISION_SCRIPT}"
    sh.env  = {
      "VBOX_VERSION" => "#{VBOX_VERSION}"
    }
  end
  
  config.hostmanager.enabled = true

  # Make sure hostmanager picks IP address of eth1
  # The operator controls the rest of the deploy
  config.vm.define "vboxcentos" do |vboxcentos|
    vboxcentos.vm.hostname = "vboxcentos#{CENTOS_MAJ_VER}.local"

    # VBoxGuestAdditions not installed yet. disable for this run
    vboxcentos.vm.synced_folder ".", get_default(:vagrant_shared_folder), disabled: true
  end

end
