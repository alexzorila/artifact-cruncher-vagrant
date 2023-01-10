# Vagrantfile used to build, configure and start Splunk Local VirtualBox VM

$msg = <<MSG
------------------------------------------------------------------------------
Access Local Splunk via:
	
  Web Interface
    Url: https://192.168.56.105:8000
    User: admin
    Password: changeme
	
  CLI via SSH
    vagrant ssh
------------------------------------------------------------------------------
MSG

# Config inspired by https://github.com/clong/DetectionLab/blob/master/Vagrant/Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.define "splunklocal" do |cfg|
    cfg.vm.box = "ubuntu/jammy64"
    cfg.vm.hostname = "splunklocal"
    cfg.vm.provision :shell, path: "bootstrap.sh"
    cfg.vm.network :private_network, ip: "192.168.56.105", gateway: "192.168.56.1", dns: "8.8.8.8"
    cfg.vm.provider "virtualbox" do |vb, override|
      vb.gui = false # Do not display Vbox VM window
      vb.name = "splunklocal"
      vb.customize ["modifyvm", :id, "--memory", 8192]
      vb.customize ["modifyvm", :id, "--cpus", 8]
      vb.customize ["modifyvm", :id, "--vram", "32"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["setextradata", "global", "GUI/SuppressMessages", "all"]
	config.vm.post_up_message = $msg
    end
  end
end
