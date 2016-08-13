# Problem Statement
When using Varant on Windows, the centos/7 vagrant-box for virtualbox 
doesnt include the virtualbox guest additions.

This makes sense since each vagrant user could be using a different 
version of virtualbox; so hard baking a version of the guest additions 
would only fit a handful of users needs. Also, the centos/7 vagrant box 
is regularly updated with security patches; so this process would be an
overhead.

Also (I suspect) the centos/7 image is currently clean of hypervisor specific 
code.

# Solution
This Vagrantfile creates a new vagrant box for virtualbox that has the 
VirtualBox guest additions installed that match your system.

The build.cmd file wraps this Vagrantfile and populates your local vagrant
box repository with a new box called vboxcentos/7.

# Setup
Expects vagrant and virtualbox to be installed and on the path

Run "vboxmanage -v" to discover version of virtualbox. Only use the first 
three versions e.g. 5.1.2

Create a Vagrantfile.custom to hold your configuration e.g.

VBOX_VERSION = "5.1.2"

TODO: Need to automate this version extract step.

# Execute
Run build.cmd

# Offline
Not really worked this through yet.

Offline operation is also supported (though it's quite arduous).

First it must be run in an environment that allows the rpms and centos 
vagrant box to be downloaded. 

These files have to be made accessible to the vagrant box (probably via squid).

# Download centos/7 vagrant box
When working offline, the centos/7 vagrantbox can be downloaded manually using a browser. 

Visit the list of centos/7 box versions:

https://atlas.hashicorp.com/centos/boxes/7

Select the version number button which supports virtualbox e.g.

https://atlas.hashicorp.com/centos/boxes/7/versions/1607.01

Then append "providers/virtualbox.box" to the end of this URL e.g.

https://atlas.hashicorp.com/centos/boxes/7/versions/1607.01/providers/virtualbox.box

Add the downloaded box to your local vagrant cache as "centos/7" ('--force' allows overwriting previous download):

vagrant box add --force centos/7 CentOS-7-x86_64-Vagrant-1607_01.VirtualBox.box
