#!/usr/bin/env bash
su ec2-user

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

sudo apt update
sudo apt upgrade -y
