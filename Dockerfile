FROM alpine:3.9

RUN apk add --update --no-cache --verbose nfs-utils bash iproute2 && \
    rm -f /sbin/halt /sbin/poweroff /sbin/reboot && \
    mkdir -p /var/lib/nfs/rpc_pipefs && \
    mkdir -p /var/lib/nfs/v4recovery && \
    echo "rpc_pipefs    /var/lib/nfs/rpc_pipefs rpc_pipefs      defaults        0       0" >> /etc/fstab && \
    echo "nfsd  /proc/fs/nfsd   nfsd    defaults        0       0" >> /etc/fstab

ADD nfsd.sh /usr/bin/nfsd.sh

EXPOSE 2049

CMD ["/usr/bin/nfsd.sh"]
