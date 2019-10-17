FROM stackbrew/debian:jessie
ENV ARCH amd64
ENV DIST stretch
ENV MIRROR http://ftp.nl.debian.org
RUN apt-get -q update
RUN apt-get -qy install dnsmasq wget iptables tcpdump vim
RUN wget --no-check-certificate https://raw.github.com/jpetazzo/pipework/master/pipework
RUN chmod +x pipework
RUN mkdir /tftp
WORKDIR /tftp
RUN wget http://ftp.debian.org/debian/dists/stretch/main/installer-amd64/current/images/netboot/netboot.tar.gz
RUN tar xvzf netboot.tar.gz -C ./
CMD \
    echo Setting up iptables... &&\
    iptables -t nat -A POSTROUTING -j MASQUERADE &&\
    echo Waiting for pipework to give us the enp0s9 interface... &&\
    /pipework --wait -i enp0s9 &&\
    myIP=$(ip addr show dev enp0s9 | awk -F '[ /]+' '/global/ {print $3}') &&\
    mySUBNET=$(echo $myIP | cut -d '.' -f 1,2,3) &&\
    echo Starting DHCP+TFTP server...&&\
    dnsmasq --interface=enp0s9 \
    	    --dhcp-range=$mySUBNET.101,$mySUBNET.199,255.255.255.0,1h \
	    --dhcp-boot=pxelinux.0,pxeserver,$myIP \
	    --pxe-service=x86PC,"Install Linux",pxelinux \
	    --enable-tftp --tftp-root=/tftp/ --no-daemon
# Let's be honest: I don't know if the --pxe-service option is necessary.
# The iPXE loader in QEMU boots without it.  But I know how some PXE ROMs
# can be picky, so I decided to leave it, since it shouldn't hurt.
