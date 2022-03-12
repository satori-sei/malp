#!/bin/bash

user () {
    grep "Changing password" ~/Install-0.log | cut -d " " -f 4;
}

ufw-fix () {
	if [ -f /usr/lib/python3.8 ];
        then
        echo "Python3.8 already installed.";
        ln -s /usr/lib/python3.10/site-packages/ufw /usr/lib/python3.8;
        else
        mkdir /usr/lib/python3.8;
        ln -s /usr/lib/python3.10/site-packages/ufw /usr/lib/python3.8;
    fi;
}

setup () {
#   print header
    echo -e "Alpine/XFCE Install log.\nUser is: $USER\n$(date)";
#   install graphics
    setup-xorg-base xfce4 lightdm-gtk-greeter dbus-x11 xf86-video-intel;
#   install system apps
    apk add xf86-input-synaptics xf86-input-mouse xf86-input-keyboard elogind polkit-elogind thunar-volman udisks2 iputils iproute2 binutils drill htop feh konsole dmenu geany mpv firefox-esr xfce4-whiskermenu-plugin neofetch gparted ntfs-3g ncdu vlc xrandr py3-pip tcpdump git keepassxc gvfs-fuse gvfs-smb fuse-openrc gvfs-mtp gvfs-gphoto2 gvfs-afc;
#   install youtube-dl
    pip install youtube-dl;
#   install flatpak
    apk add flatpak;
#   add flatpak repo
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo;
#   install alsa
    apk add alsa-utils alsa-utils-doc alsa-lib alsaconf;
#   include home folder to lbu captures
    lbu include /home;
#   add users to audio group
    addgroup root audio;
    addgroup $(user) audio;
#   raise volume levels
    amixer set Master unmute;
    amixer set Master 100%;
    amixer set PCM unmute;
    amixer set PCM 100%;
#   audio service
    rc-service alsa start;
    rc-update add alsa;
#   fuse service
    rc-service fuse start;
    rc-update add fuse;
#   dbus service
    rc-service dbus start;
    rc-update add dbus;
#   lightdm service
    rc-update add lightdm;
#   create Xorg file
    Xorg -configure;
#   move new Xorg conf file to /etc/X11/xorg.conf
    mv -v /root/xorg.conf.new /etc/X11/xorg.conf;
#   create .xinitrc
    echo "exec xfce4-session" >> ~/.xinitrc;
    echo -e "xinitrc Built.\nInstallation Done.";
}

fw () {
#   modify repo list
    echo "Adding edge/community to repository list...";
    echo -e "http://dl-cdn.alpinelinux.org/alpine/v3.12/main\nhttp://dl-cdn.alpinelinux.org/alpine/v3.12/community\n#http://dl-cdn.alpinelinux.org/alpine/edge/main\nhttp://dl-cdn.alpinelinux.org/alpine/edge/community\n#http://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories;
    echo "Updating repository list...";
    apk update;

    echo "Installing ufw.";
    apk add iptables ip6tables ufw;

#   create ufw symlink to python3.8
    ufw-fix;

    echo "Setting up basic firewall rules.";
    ufw default deny incoming;
    ufw default deny outgoing;
    ufw allow out 123/udp;       # allow outgoing NTP (Network Time Protocol)
    ufw allow out DNS;           # allow outgoing DNS
    ufw allow out 80/tcp;        # allow outgoing HTTP traffic
    ufw allow out 443/tcp;       # allow outgoing HTTPS traffic
#   ufw limit SSH;               # open SSH port and protect against brute-force login attacks

#   the following lines are only needed the first time you install the package
    echo "Enabling firewall and adding to startup.";
    ufw enable;                  # enable the firewall
    rc-update add ufw;           # add UFW init scripts

#   check the status of UFW
    echo "Check firewall status:"
    ufw status;

#   modify repo list
    echo "Removing edge/communiy from repository list..."
    echo -e "http://dl-cdn.alpinelinux.org/alpine/v3.12/main\nhttp://dl-cdn.alpinelinux.org/alpine/v3.12/community\n#http://dl-cdn.alpinelinux.org/alpine/edge/main\n#http://dl-cdn.alpinelinux.org/alpine/edge/community\n#http://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories;
    echo "Updating repository list..."
    apk update;
}

cpstuff (){
#   copy some user files
    cp -v /opt/malp/get/profile /etc/profile;
    cp -v /opt/malp/get/inittab /etc/inittab;
    cp -v /opt/malp/get/.bashrc /root/;
    cp -v /opt/malp/get/.bashrc /home/$(user)/;
    cp -v /opt/malp/get/vimrc /etc/vim/vimrc;
    cp -v /opt/malp/bin/* /usr/local/bin/;
    cp -v /opt/malp/get/bg.png /usr/share/backgrounds/xfce/;
    cp -v /opt/malp/get/colorschemes/* /usr/share/geany/colorschemes/;
    chmod 755 /usr/local/bin/*;
}

if [ $USER != 'root' ];
then
    echo "You must be root to do this.";
    exit;
else
    fw | tee ~/fw.log;
    setup | tee ~/Install-1.log;
    cpstuff | tee ~/user-files.log;
fi;

reboot;

exit;
