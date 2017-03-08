# -*- mode: ruby -*-
# vi: set ft=ruby :

# Global
Vagrant.configure("2") do |config|

  config.vm.box = "bento/centos-7.3"
  config.ssh.forward_agent = true
  config.ssh.insert_key = false
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 1
  end
  # Zookeeper & Kafka Instances => 3 Instances Spawned
  (1..3).each do |i|
    config.vm.define "zkafka#{i}" do |s|
      s.vm.hostname = "zkafka#{i}"
      s.vm.network "private_network", ip: "10.30.3.#{i+1}", netmask: "255.255.255.0"
      s.vm.provision "shell", path: "scripts/zkafka.sh", args:"#{i}", privileged: true

    end
  end

  # Logstash Instance => 1 Instance Spawned
  (1..1).each do |i|
    config.vm.define "logstash1" do |s|
      s.vm.define "logstash1"
      s.vm.hostname = "logstash1"
      s.vm.network "private_network", ip: "10.30.3.5", netmask: "255.255.255.0"
      s.vm.provision "shell", path: "scripts/logstash.sh", privileged: true
      s.vm.provider "virtualbox" do |v|
        v.memory = 2048
        v.cpus = 1
      end
    end
  end

  # Connector Instance => 1 Instance Spawned
  (1..1).each do |i|
    config.vm.define "connector1" do |s|
      s.vm.define "connector1"
      s.vm.hostname = "connector1"
      s.vm.network "private_network", ip: "10.30.3.6", netmask: "255.255.255.0"
      s.vm.provision "shell", path: "scripts/connector.sh", privileged: true
      s.vm.provider "virtualbox" do |v|
        v.memory = 2048
        v.cpus = 1
      end
    end
  end

# Global
end
