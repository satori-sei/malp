#!/bin/bash

mkuser () {
    echo -e "$password\n$password\n" | adduser ${username};
}

pass () {
    read -r -p "Select username: " username;
    read -r -s -p "Select password: " password;
}
setup () {
#   print header
    echo -e "Alpine/XFCE Install log.\nUser is: $USER\n$(date)";
#   create user
    mkuser;
#   hushlogin
    echo > /etc/motd;
#   edit repo list
    echo -e "http://dl-cdn.alpinelinux.org/alpine/v3.12/main\nhttp://dl-cdn.alpinelinux.org/alpine/v3.12/community\n#http://dl-cdn.alpinelinux.org/alpine/edge/main\n#http://dl-cdn.alpinelinux.org/alpine/edge/community\n#http://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories & echo "Adding community to repository list...";
#   update repo
    apk update & echo "Updating repository list...";
#   install sudo vim bash
    apk add sudo vim bash;
#   edit passwd file to replace ash for bash
    sed -i 's/ash/bash/g' /etc/passwd;
#   add networking to boot
    rc-update add networking boot;
}

if [ $USER != 'root' ];
then
    echo "You must be root to do this.";
    exit;
else
    pass; setup | tee ~/Install-0.log;
    #   give new user sudo permissions in /etc/sudoers
    visudo;
fi;

exit;
