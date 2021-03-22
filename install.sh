#!/bin/bash

user () {
    grep "Changing password" ~/Install-0.log | cut -d " " -f 4;
}

check-xorg () {
    if [ -f /etc/X11/xorg.conf ];
        then
        echo "Backing up old Xorg conf file.";
        mv -v /etc/X11/xorg.conf /etc/X11/xorg.bak;
        else
        echo "Xorg conf doesn't exist.";
    fi
}

setup () {
#   print header
    echo -e "Alpine/XFCE Install log.\nUser is: $USER\n$(date)";
#   install graphics
    setup-xorg-base xfce4 lightdm-gtk-greeter dbus-x11 xf86-video-intel;
#   install system apps
    apk add xf86-input-synaptics xf86-input-mouse xf86-input-keyboard elogind polkit-elogind gvfs-fuse gvfs-smb fuse-openrc thunar-volman udisks2 htop feh konsole dmenu geany mpv firefox-esr xfce4-whiskermenu-plugin neofetch gparted ntfs-3g gvfs-mtp gvfs-gphoto2 gvfs-afc ncdu vlc xrandr py3-pip tcpdump git keepassxc;
#   install pip
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
#   start audio service
    rc-service alsa start;
#   add alsa service to boot
    rc-update add alsa;
#   start fuse service
    rc-service fuse start
#   add fuse service to boot
    rc-update add fuse
#   start dbus service
    rc-service dbus start;
#   add dbus service to boot
    rc-update add dbus;
#   add lightdm service to boot
    rc-update add lightdm;
#   create Xorg file
    Xorg -configure;
#   check if Xorg conf file already exists
    check-xorg;
#   move new Xorg conf file to /etc/X11/xorg.conf
    mv -v /root/xorg.conf.new /etc/X11/xorg.conf;
#   create .xinitrc
    echo "exec xfce4-session" >> ~/.xinitrc &
    echo -e "xinitrc Built.\nInstallation Done.";
}

fw () {
#   modify repo list
    echo -e "http://dl-cdn.alpinelinux.org/alpine/v3.12/main\nhttp://dl-cdn.alpinelinux.org/alpine/v3.12/community\n#http://dl-cdn.alpinelinux.org/alpine/edge/main\nhttp://dl-cdn.alpinelinux.org/alpine/edge/community\n#http://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories & echo "Adding edge/testing to repository list...";
    echo "Updating repository list";
    apk update;

    echo "Installing ufw.";
    apk add iptables ip6tables ufw;
    ufw default deny incoming;
    ufw default deny outgoing;

    echo "Setting up basic firewall rules.";
    ufw allow out 123/udp;       # allow outgoing NTP (Network Time Protocol)
    ufw allow out DNS;           # allow outgoing DNS
    ufw allow out 80/tcp;        # allow outgoing HTTP traffic
    ufw allow out 443/tcp;       # allow outgoing HTTPS traffic
#   ufw limit SSH;               # open SSH port and protect against brute-force login attacks

#   the following lines are only needed the first time you install the package:
    echo "Enabling firewall and adding to startup.";
    ufw enable;                  # enable the firewall
    rc-update add ufw;           # add UFW init scripts

#   check the status of UFW:
    echo "Check firewall status:"
    ufw status;

#   modify repo list
    echo -e "http://dl-cdn.alpinelinux.org/alpine/v3.12/main\nhttp://dl-cdn.alpinelinux.org/alpine/v3.12/community\n#http://dl-cdn.alpinelinux.org/alpine/edge/main\n#http://dl-cdn.alpinelinux.org/alpine/edge/community\n#http://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories & echo "Removing edge/testing from repository list...";
    echo "Updating repository...";
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
}

if [ $USER != 'root' ];
then
    echo "You must be root to do this.";
exit;
else
    setup | tee ~/Install-1.log;
    fw | tee ~/fw.log;
    cpstuff | tee ~/user-files.log;
    chmod 755 /usr/local/bin/*;
fi;

reboot;

exit;
