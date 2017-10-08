FROM ubuntu:16.04

ARG RHODECODE_USER_UID=1000
ARG RHODECODE_USER_GID=1000

ENV RHODECODE_SVN_SHARED_DIR=/home/rhodecode/shared

# upgrade & install wget
RUN apt-get update \
 && apt-get -y upgrade \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    lsb-release wget supervisor \
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
COPY apache2/000-default.conf /etc/apache2/sites-available/

# create rhodecode user/group
RUN groupadd -g ${RHODECODE_USER_GID} rhodecode
RUN useradd -u ${RHODECODE_USER_UID} -g ${RHODECODE_USER_GID} -m rhodecode

# make a directory shared with rhodecode container
RUN mkdir -p ${RHODECODE_SVN_SHARED_DIR}
RUN touch ${RHODECODE_SVN_SHARED_DIR}/mod_dav_svn.conf

# change running user/group of apache
RUN sed -i -e 's/APACHE_RUN_USER=.*/APACHE_RUN_USER=rhodecode/g' -e 's/APACHE_RUN_GROUP=.*/APACHE_RUN_GROUP=rhodecode/g' /etc/apache2/envvars
RUN chown rhodecode:rhodecode /var/run /var/lock
RUN chown -R rhodecode:rhodecode ${RHODECODE_SVN_SHARED_DIR} /var/log/apache2 /var/log/supervisor

# setup rhodecode
COPY supervisor/*.conf /etc/supervisor/conf.d/
USER rhodecode
CMD ["/usr/bin/supervisord"]
