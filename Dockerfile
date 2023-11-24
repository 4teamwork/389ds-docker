FROM alpine:3.18 as build-stage

ARG VERSION=2.4.4

RUN apk add --no-cache \
    autoconf \
    automake \
    build-base \
    bzip2-dev \
    cargo \
    clang16 \
    compiler-rt \
    cracklib-dev \
    cyrus-sasl-dev \
    db-dev \
    icu-dev \
    json-c-dev \
    krb5-dev \
    libatomic \
    libtool \
    linux-pam-dev \
    lld \
    lmdb-dev \
    net-snmp-dev \
    nspr-dev \
    nss-dev \
    openldap-dev \
    openssl-dev \
    pcre2-dev \
    python3 \
    python3-dev \
    py3-argcomplete \
    py3-cryptography \
    py3-dateutil \
    py3-pip \
    py3-pyldap \
    py3-setuptools \
    rust

RUN pip3 install \
    argparse_manpage \
    pyasn1 \
    pyasn1-modules

RUN mkdir /build
WORKDIR /build

RUN wget https://github.com/389ds/389-ds-base/archive/refs/tags/389-ds-base-${VERSION}.tar.gz && \
    tar xzvf 389-ds-base-${VERSION}.tar.gz

COPY remove_execinfo.patch /build

RUN cd 389-ds-base-389-ds-base-${VERSION} && \
    patch -p 1 -i ../remove_execinfo.patch

RUN cd 389-ds-base-389-ds-base-${VERSION} && \
     autoreconf -fiv && \
     ./configure \
         --build=x86_64-pc-linux-musl \
         --host=x86_64-pc-linux-musl \
         --prefix=/usr \
         --sysconfdir=/etc \
         --localstatedir=/var \
         --enable-clang \
         --disable-cockpit \
         --disable-dependency-tracking \
         --with-openldap \
         --with-pythonexec=python3 \
         --without-selinux \
         --without-systemd

RUN cd 389-ds-base-389-ds-base-${VERSION} && \
    make && \
    make lib389 && \
    make check && \
    DESTDIR=/out make install && \
    cd src/lib389 && \
    python3 setup.py install --skip-build --root=/out

RUN rm -rf /out/dirsrv@.service.d

CMD ["/bin/sh"]


FROM alpine:3.18

RUN apk add --no-cache \
    ca-certificates \
    cracklib \
    db \
    icu-libs \
    json-c \
    krb5 \
    libgcc \
    libldap \
    linux-pam \
    lmdb \
    net-snmp-libs \
    net-snmp-agent-libs \
    nspr \
    nss-tools \
    openldap-clients \
    openssl \
    pcre2 \
    python3

RUN adduser -D -h /var/run/dirsrv dirsrv

COPY --from=build-stage /usr/lib/python3.11/site-packages/ /usr/lib/python3.11/site-packages/
COPY --from=build-stage /out /

RUN mkdir -p /data/config && \
    mkdir -p /data/ssca && \
    mkdir -p /data/run && \
    chown dirsrv:dirsrv /data/config && \
    chown dirsrv:dirsrv /data/ssca && \
    chown dirsrv:dirsrv /data/run && \
    ln -s /data/config /etc/dirsrv/slapd-localhost && \
    ln -s /data/ssca /etc/dirsrv/ssca && \
    ln -s /data/run /var/run/dirsrv

VOLUME /data

EXPOSE 3389 3636

# USER dirsrv

CMD [ "/usr/libexec/dirsrv/dscontainer", "-r" ]
HEALTHCHECK --start-period=5m --timeout=5s --interval=5s --retries=2 CMD /usr/libexec/dirsrv/dscontainer -H
