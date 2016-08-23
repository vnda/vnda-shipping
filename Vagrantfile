# -*- mode: ruby -*-
unless Vagrant.has_plugin?("vagrant-docker-compose")
  system("vagrant plugin install vagrant-docker-compose")
  puts "Dependencies installed, please try the command again."
  exit
end

Vagrant.configure(2) do |config|
  config.vm.define :shipping
  config.vm.box = "minimal/trusty64"
  config.vm.hostname = "shipping.dev"
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.vm.network :private_network, ip: '192.168.99.100'
  config.vm.network :forwarded_port, guest: 80, host: 2376      # Docker Socket
  config.vm.network :forwarded_port, guest: 9000, host: 9000    # rails
  config.vm.network :forwarded_port, guest: 4567, host: 4567    # sinatra
  config.vm.network :forwarded_port, guest: 1025, host: 1025    # Mailcatcher SMTP
  config.vm.network :forwarded_port, guest: 1080, host: 1080    # mailcatcher
  config.vm.network :forwarded_port, guest: 5432, host: 5432    # postgresql
  config.vm.network :forwarded_port, guest: 6379, host: 6379    # redis
  config.vm.network :forwarded_port, guest: 9200, host: 9200    # elasticsearch
  config.vm.network :forwarded_port, guest: 80, host: 80        # apache/nginx

  config.vm.synced_folder '.', '/usr/src/app', nfs: true

  config.vm.provision :docker
  config.vm.provision :docker_compose, compose_version: '1.7.1', yml: '/usr/src/app/docker-compose.yml', project_name: 'shipping', rebuild: true, run: 'always'

  config.vm.provider :virtualbox do |virtualbox|
    virtualbox.cpus   = 2
    virtualbox.memory = 2048
    virtualbox.name   = "shipping"
  end
end
