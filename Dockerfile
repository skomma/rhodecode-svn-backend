FROM ubuntu:16.04

# upgrade & install wget
RUN apt-get update \
 && apt-get -y upgrade \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    lsb-release wget \
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
