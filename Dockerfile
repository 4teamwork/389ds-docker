FROM alpine:3.14 as build-stage

ARG VERSION=2.0.7

RUN apk add --no-cache \
    autoconf \
    automake \
    build-base \
    bzip2-dev \
    cargo \
    cmocka-dev \
    clang \
    compiler-rt \
    cracklib-dev \
    cyrus-sasl-dev \
    db-dev \
    doxygen \
    icu-dev \
    krb5-dev \
    libatomic \
    libevent-dev \
    libtool \
    linux-pam-dev \
    lld \
    net-snmp-dev \
    nspr-dev \
    nss-dev \
    openldap-dev \
    openssl-dev \
    pcre-dev \
    pkgconf \
    python3 \
    python3-dev \
    py3-dateutil \
    py3-pip \
    py3-setuptools \
    rust \
    zlib-dev

RUN pip3 install \
    argparse_manpage \
    argcomplete \
    python-ldap \
    pyasn1 \
    pyasn1-modules

RUN wget https://github.com/389ds/389-ds-base/archive/refs/tags/389-ds-base-${VERSION}.tar.gz && \
    tar xzvf 389-ds-base-${VERSION}.tar.gz

RUN cd 389-ds-base-389-ds-base-${VERSION} && \
    autoreconf -fiv && \
    ./configure \
        --build=x86_64-pc-linux-musl \
        --host=x86_64-pc-linux-musl \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --enable-cmocka \
        --enable-rust \
        --enable-clang \
        --disable-cockpit \
        --disable-dependency-tracking \
        --with-openldap \
        --with-pythonexec=python3 \
        --without-selinux \
        --without-systemd \
    make && \
    make lib389 && \
    make check && \
    DESTDIR=/out make install && \
    cd src/lib389 && \
    python3 setup.py install --skip-build --root=/out

RUN rm -rf /out/dirsrv@.service.d


FROM alpine:3.14

RUN apk add --no-cache \
    ca-certificates \
    cracklib \
    db \
    icu-libs \
    krb5 \
    libgcc \
    libldap \
    linux-pam \
    nspr \
    nss-tools \
    openldap-clients \
    openssl \
    pcre \
    python3

RUN adduser -D -h /var/run/dirsrv dirsrv

COPY --from=build-stage /usr/lib/python3.9/site-packages/ /usr/lib/python3.9/site-packages/
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
