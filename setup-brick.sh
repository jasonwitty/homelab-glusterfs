#!/bin/bash

###
# Date: 2022-08-13
#
# REQUIRES debian based distribution. Tested on ubuntu-22.04-5.4-minimal-odroid-xu4-20220721.
#
# Usage:
#          sudo bash setup-brick.sh gluster-hosts.txt odroid7 /dev/sda
#          arguments: hostfiles, hostname, drive name
# NOTE:
#          Requires sudo permissions, this will restart your system after completion.
#          If you are using an SSD the disk name will usually be /dev/sda but if you are using an nvme it could be nvme0n1, please verify using the "lsblk -f" if you are unsure of disk name.
# AUTHOR: 
#	   Jason Witty
# CONTACT: 
#	   jasonwitty@gmail.com
###

###
# Set hostname
###
echo "UPDATE:::: Setting hostname to $2"
hostname "$2"

###
## Setup NALA
###

# setup repo
echo "deb https://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null

#add source repo
echo "deb-src https://deb.volian.org/volian/ scar main" | sudo tee -a /etc/apt/sources.list.d/volian-archive-scar-unstable.list

#install nala
#Ubuntu 22.04 / Debian Testing/Sid
echo "UPDATE:::: install nala"
apt update && apt install nala -y

#Ubuntu 21.04 / Debian Stable
#uncomment if installing on earlier version of 
#apt update && sudo apt install nala-legacy

###
# Fetch fastest mirrors and select 1-3
###
echo "UPDATE:::: fetching fastest mirrors"
nala fetch --auto -y

###
# update system now that optimal mirrors selected
###
echo "UPDATE:::: running update"
nala update
nala upgrade -y

###
# Install common utils git,curl,htop,neofetch
###
echo "UPDATE:::: install common utilities"
nala install git curl htop neofetch iputils-ping micro software-properties-common -y

###
# Add neofetch to .bashrc
##
echo "UPDATE:::: Add neofetch to .bashrc"
echo "" >> .bashrc
echo "clear" >> .bashrc
echo "neofetch" >> .bashrc

###
# Partition HDD
# Please note this assumes your partition /dev/sda unless overriden
# Use switch --nopart to avoid rebuilding drives if you just want to resinstall
###
echo "UPDATE:::: Partition HDD $3"
(
echo g # creates a new gpt partition
echo n # creates a new partition
echo 1
echo
echo
echo w # accepts the changes and writes them to the disk
) | fdisk $3

#make it an ext4 partition
mkfs.ext4 /dev/sda1

###
# Mount Disk
###

echo "UPDATE:::: Mount Disk"
#make a directory to mount our volume
mkdir -p /gfs/brick1

#add to fstab
echo "/dev/sda1 /gfs/brick1 ext4 defaults 0 1" >> /etc/fstab

#Mount
mount -a

###
# Add gluster repo
###
echo "UPDATE:::: Add gluster repo"

add-apt-repository ppa:gluster/glusterfs-8
nala update

###
# install gluster-fs server
###
echo "UPDATE:::: install gluster-fs server"

nala install glusterfs-server -y

###
# Set hosts
# this uses the file passed in at the command line to append hosts.
# it will also prepend current hostname to local hosts.
###
echo "UPDATE:::: setting host files"

echo "#hostname added by glusterfs setup script" >> /etc/hosts
echo "127.0.0.1     $2" >> /etc/hosts
echo "" >> /etc/hosts
echo "#added by glusterfs setup script" >> /etc/hosts
cat $1 >> test-dest.txt >> /etc/hosts

###
# Brick Setup complete !
# See https://www.wittyoneoff.com/gluster-fs for next steps.
###
echo "Brick Setup complete !"
echo "See https://www.wittyoneoff.com/gluster-fs for next steps."
echo "Restarting now ..."

###
# restart
###
shutdown -r now