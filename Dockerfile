FROM odoo:11.0
MAINTAINER OpusVL <community@opusvl.com>

ENV PG_MAJOR 10

USER root

# Install some more fonts and locales
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        fonts-dejavu \
        fonts-dejavu-core \
        fonts-dejavu-extra \
        unzip \
        locales-all \
        locales \
        gnupg \
        dirmngr \
    && rm -rf /var/lib/apt/lists/*


### MAKE DATABASE MANAGER WORK WITH PostgreSQL 10 ###
# pub   4096R/ACCC4CF8 2011-10-13 [expires: 2019-07-02]
#       Key fingerprint = B97B 0AFC AA1A 47F0 44F2  44A0 7FCC 7D46 ACCC 4CF8
# uid                  PostgreSQL Debian Repository
RUN set -ex; \
    key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'; \
    export GNUPGHOME="$(mktemp -d)"; \
    ( \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" \
    || gpg --keyserver pgp.mit.edu --recv-keys "$key" \
    || gpg --keyserver keyserver.pgp.com --recv-keys "$key" \
  ) ; \
    gpg --export "$key" > /etc/apt/trusted.gpg.d/postgres.gpg; \
    rm -rf "$GNUPGHOME"; \
  apt-key list
RUN set -ex; \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main $PG_MAJOR" > /etc/apt/sources.list.d/pgdg.list; \
            apt-get update ; \
apt-get -y install "postgresql-client-$PG_MAJOR" postgresql-client-9.4-

# Install barcode font
COPY pfbfer.zip /root/pfbfer.zip
RUN mkdir -p /usr/lib/python2.7/dist-packages/reportlab/fonts \
        && unzip /root/pfbfer.zip -d /usr/lib/python2.7/dist-packages/reportlab/fonts/

# Generate British locales, as this is who we mostly serve
RUN locale-gen en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB:en
ENV LC_ALL en_GB.UTF-8

RUN mkdir /mnt/extra-addons-bundles && chmod -R 755 /mnt/extra-addons-bundles

COPY ./odoo.conf /etc/odoo/

# This custom entypoint augments the environment variables and the command line, and then despatches to the upstream /entrypoint.sh
COPY opusvl-entrypoint.py /
RUN chmod a+rx /opusvl-entrypoint.py
ENTRYPOINT ["/opusvl-entrypoint.py"]

USER odoo

ONBUILD USER root
ONBUILD COPY ./addon-bundles/ /mnt/extra-addons-bundles/
ONBUILD RUN chmod -R u=rwX,go=rX /mnt/extra-addons-bundles
ONBUILD COPY ./requirements.txt /root/
ONBUILD RUN pip3 install -r /root/requirements.txt
ONBUILD USER odoo
