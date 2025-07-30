# syntax=docker/dockerfile:1
#
ARG COMPILERIMAGE=debian:sid-slim
ARG IMAGEBASE=frommakefile
#
# {{{ -- fetch and compile source using a glibc-supported image
FROM ${COMPILERIMAGE} AS glibc-compiler
#
ARG GLIBCVERSION=2.31
ARG NPROC=8
#
ENV \
    DEBIAN_FRONTEND=noninteractive \
    PREFIX_DIR=/usr/glibc-compat
#
RUN set -xe \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get update \
    && apt-get install -y binutils build-essential curl openssl gawk bison python3 gettext texinfo \
    && mkdir -p /glibc/build \
    && echo "Using GLIBC Version: $GLIBCVERSION" \
    && curl \
        --retry 3 --retry-all-errors \
        -jSLN https://ftpmirror.gnu.org/glibc/glibc-${GLIBCVERSION}.tar.gz \
        -o /tmp/glibc-${GLIBCVERSION}.tar.gz \
    # TODO: source verification steps
    && tar xzf /tmp/glibc-${GLIBCVERSION}.tar.gz -C /glibc --strip 1 \
    && cd /glibc/build \
    && /glibc/configure \
        --prefix=${PREFIX_DIR} \
        --libdir=${PREFIX_DIR}/lib \
        --libexecdir=${PREFIX_DIR}/lib \
        # --enable-multi-arch \
        --enable-stack-protector=strong \
    && make -j${NPROC} \
    && make install \
    && tar --hard-dereference -zcf /glibc-bin-${GLIBCVERSION}.tar.gz ${PREFIX_DIR} \
    && sha512sum /glibc-bin-${GLIBCVERSION}.tar.gz > /glibc-bin-${GLIBCVERSION}.sha512sum
# }}} --
#
# {{{ -- build apk packages
FROM ${IMAGEBASE} AS glibc-alpine-builder
#
ARG APKBUILD=APKBUILD
ARG GLIBCARCH=frommakefile
ARG GLIBCVERSION=2.31
ARG GLIBC_RELEASE=0
ARG PACKAGER=woahbase
#
RUN set -xe \
    && apk add -Uu \
        alpine-sdk \
        bash \
        coreutils \
        cmake \
        libc6-compat \
        sudo \
    && adduser -G abuild -g "Alpine Package Builder" -s /bin/ash -D builder \
    && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /packages /home/builder/package/ \
    && chown builder:abuild /packages /home/builder/package /etc/apk/keys
#
USER builder
WORKDIR /home/builder/package/
#
COPY --from=glibc-compiler /glibc-bin-${GLIBCVERSION}.tar.gz .
COPY --from=glibc-compiler /glibc-bin-${GLIBCVERSION}.sha512sum .
COPY files/${APKBUILD} ./APKBUILD
COPY files/glibc-bin.trigger .
COPY files/ld.so.conf .
COPY files/nsswitch.conf .
#
ENV \
    ABUILD_KEY_DIR=/home/builder/.abuild \
    GLIBCARCH=${GLIBCARCH} \
    GLIBCVERSION=${GLIBCVERSION} \
    REPODEST=/packages
#
RUN set -xe \
    && mkdir -p ${ABUILD_KEY_DIR} ${REPODEST}/builder \
    && openssl genrsa -out ${ABUILD_KEY_DIR}/${PACKAGER}.rsa 2048 \
    && openssl rsa -in ${ABUILD_KEY_DIR}/${PACKAGER}.rsa -pubout -out ${ABUILD_KEY_DIR}/${PACKAGER}.rsa.pub \
    && cp ${ABUILD_KEY_DIR}/${PACKAGER}.rsa.pub /etc/apk/keys/${PACKAGER}.rsa.pub \
    && echo "PACKAGER_PRIVKEY=\"${ABUILD_KEY_DIR}/${PACKAGER}.rsa\"" > ${ABUILD_KEY_DIR}/abuild.conf \
    && sed -i "s/<\${GLIBCVERSION}-checksum>/$(cat glibc-bin-${GLIBCVERSION}.sha512sum | awk '{print $1}')/" APKBUILD \
    && abuild -r \
    && find ${REPODEST}
# }}} --
#
# {{{ -- install built apk packages and generate final image
FROM ${IMAGEBASE}
#
ARG GLIBCARCH=frommakefile
ARG GLIBC_RELEASE=0
ARG GLIBCVERSION=2.31
# ARG PACKAGER=woahbase
#
# keep a copy of built package(s) (in /opt/glibc) for future need??
# COPY --from=glibc-compiler /glibc-bin-${GLIBCVERSION}.tar.gz /opt/glibc/
# COPY --from=glibc-compiler /glibc-bin-${GLIBCVERSION}.sha512sum /opt/glibc/
COPY --from=glibc-alpine-builder /packages/builder/${GLIBCARCH}/glibc-${GLIBCVERSION}-r${GLIBC_RELEASE}.apk /opt/glibc/
COPY --from=glibc-alpine-builder /packages/builder/${GLIBCARCH}/glibc-bin-${GLIBCVERSION}-r${GLIBC_RELEASE}.apk /opt/glibc/
COPY --from=glibc-alpine-builder /packages/builder/${GLIBCARCH}/glibc-i18n-${GLIBCVERSION}-r${GLIBC_RELEASE}.apk /opt/glibc/
# COPY --from=glibc-alpine-builder /etc/apk/keys/${PACKAGER}.rsa.pub /etc/apk/keys/${PACKAGER}.rsa.pub
#
RUN set -xe \
    && apk add -Uu --no-cache libstdc++ \
    && apk add --allow-untrusted --force-overwrite /opt/glibc/glibc-*.apk \
    && ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) \
    && echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh \
    && /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib \
    # && echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' > /etc/nsswitch.conf \
    && rm -rf /var/cache/apk/* /tmp/* /opt/glibc
        # /etc/apk/keys/${PACKAGER}.rsa.pub
# }}} --
#
ENV PATH=/usr/glibc-compat/sbin:/usr/glibc-compat/bin:${PATH}
#
# ENTRYPOINT ["/init"]
# CMD ["/bin/bash"]
#
# no need to preserve built packages (in /opt/glibc) on child images
# ONBUILD RUN set -xe \
#     && rm -rf /opt/glibc
