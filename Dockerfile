FROM ubuntu:16.04

ARG RHODECODE_USER_UID=1000
ARG RHODECODE_USER_GID=1000

ENV RHODECODE_SVN_SHARED_DIR=/home/rhodecode/shared
ENV DAV_SVN_CONF_PATH=${RHODECODE_SVN_SHARED_DIR}/mod_dav_svn.conf

# upgrade & install wget
RUN apt-get update \
 && apt-get -y upgrade \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    lsb-release wget supervisor inotify-tools \
 && rm -rf /var/lib/apt/lists/*

# add subversion repository
RUN echo "deb http://opensource.wandisco.com/ubuntu `lsb_release -cs` svn19" >> /etc/apt/sources.list.d/subversion19.list
RUN wget -q http://opensource.wandisco.com/wandisco-debian.gpg -O- | apt-key add -

# install apache2/dav_svn
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    apache2 libapache2-svn \
 && rm -rf /var/lib/apt/lists/*

# enable required Apache modules as Rhodecode SVN backend
RUN a2enmod dav_svn headers authn_anon

# place backend server configuration
RUN sed -ie 's/Listen 80/Listen 8090/g' /etc/apache2/ports.conf
RUN sed -ie 's/^ErrorLog.*/ErrorLog \/dev\/stderr/' /etc/apache2/apache2.conf
COPY apache2/000-default.conf /etc/apache2/sites-available/

# suppress AH00558 warning
COPY apache2/fqdn.conf /etc/apache2/conf-available/
RUN a2enconf fqdn

# create rhodecode user/group
RUN groupadd -g ${RHODECODE_USER_GID} rhodecode
RUN useradd -u ${RHODECODE_USER_UID} -g ${RHODECODE_USER_GID} -m rhodecode

# make a directory shared with rhodecode container
RUN mkdir -p ${RHODECODE_SVN_SHARED_DIR}
RUN touch ${RHODECODE_SVN_SHARED_DIR}/mod_dav_svn.conf

# change running user/group of apache
RUN sed -i -e 's/APACHE_RUN_USER=.*/APACHE_RUN_USER=rhodecode/g' -e 's/APACHE_RUN_GROUP=.*/APACHE_RUN_GROUP=rhodecode/g' /etc/apache2/envvars
RUN mkdir -p /var/lock/apache2 /var/run/apache2
RUN chown rhodecode:rhodecode /var/run /var/run/apache2 /var/lock/apache2
RUN chown -R rhodecode:rhodecode ${RHODECODE_SVN_SHARED_DIR} /var/log/apache2 /var/log/supervisor

# place supervisor configurations
COPY supervisor/*.conf /etc/supervisor/conf.d/
COPY watch-apache2-conf.sh /usr/local/bin
RUN chmod +x /usr/local/bin/watch-apache2-conf.sh

USER rhodecode
EXPOSE 8090
CMD ["/usr/bin/supervisord"]
