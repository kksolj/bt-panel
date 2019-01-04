FROM centos:latest
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

ENV REMOTE_PATH=https://github.com/ywfwj2008/bt-panel/raw/master \
    LIBMEMCACHED_VERSION=1.0.18

WORKDIR /tmp

RUN yum install -y wget cyrus-sasl-devel

# install bt panel
ADD ${REMOTE_PATH}/install_6.0.sh /tmp/install.sh
RUN chmod 777 install.sh \
    && bash install.sh \
    && rm -rf /tmp/*

# install pure-ftpd
RUN cd /www/server/panel/install \
    && wget -O lib.sh http://download.bt.cn/install/0/lib.sh \
    && bash lib.sh \
    && bash install_soft.sh 0 install pure-ftpd \
    && rm -rf /tmp/*

RUN wget https://sourceforge.net/projects/re2c/files/1.0.1/re2c-1.0.1.tar.gz \
    && tar zxf re2c-1.0.1.tar.gz \
    && cd re2c-1.0.1 \
    && ./configure \
    && make && make install \
    && cd /tmp \
    && wget https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz \
    && tar zxf libiconv-1.15.tar.gz \
    && cd libiconv-1.15 \
    && ./configure \
    && make && make install \
    && rm -rf /tmp/*

# install libmemcached
ADD ${REMOTE_PATH}/libmemcached-build.patch /tmp/libmemcached-build.patch
RUN wget -c --no-check-certificate https://launchpad.net/libmemcached/1.0/${LIBMEMCACHED_VERSION}/+download/libmemcached-${LIBMEMCACHED_VERSION}.tar.gz \
    && tar xzf libmemcached-${LIBMEMCACHED_VERSION}.tar.gz \
    && patch -d libmemcached-${LIBMEMCACHED_VERSION} -p0 < /tmp/libmemcached-build.patch \
    && cd libmemcached-${LIBMEMCACHED_VERSION} \
    && ./configure \
    && make && make install \
    && rm -rf /tmp/*

# install supervisord
ADD ./supervisord.conf /etc/supervisor/supervisord.conf
RUN pip install supervisor \
    && mkdir -p /etc/supervisor/conf.d /var/log/supervisor \
    && rm -rf /tmp/*

# expose port
EXPOSE 8888 80 443 21 20 888 3306 9001

# Set the entrypoint script.
ADD ${REMOTE_PATH}/entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#Define the default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
