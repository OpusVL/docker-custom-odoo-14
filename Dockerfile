FROM debian:buster-slim
MAINTAINER Odoo S.A. <info@odoo.com>

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            dirmngr \
            fonts-noto-cjk \
            gnupg \
            libssl-dev \
            node-less \
            npm \
            python3-num2words \
            python3-pip \
            python3-pdfminer \
            python3-phonenumbers \
            python3-pyldap \
            python3-qrcode \
            python3-renderpm \
            python3-setuptools \
            python3-slugify \
            python3-vobject \
            python3-watchdog \
            python3-xlrd \
            python3-xlwt \
            xz-utils \
            fonts-dejavu \
            fonts-dejavu-core \
            fonts-dejavu-extra \
            unzip \
            locales-all \
            locales \
            gnupg \
            dirmngr \
        && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb \
        && echo '7e35a63f9db14f93ec7feeb0fce76b30c08f2057 wkhtmltox.deb' | sha1sum -c - \
        && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# install latest postgresql-client
RUN set -x; \
        echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' > etc/apt/sources.list.d/pgdg.list \
        && export GNUPGHOME="$(mktemp -d)" \
        && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
        && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
        && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
        && gpgconf --kill all \
        && rm -rf "$GNUPGHOME" \
        && apt-get update  \
        && apt-get install -y postgresql-client \
        && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Install Odoo
ENV ODOO_VERSION 14.0
ARG ODOO_RELEASE=20220111
ARG ODOO_SHA=59f4f42dac5b3e2f8deb22109ca440e90d139476
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
    && echo "${ODOO_SHA} odoo.deb" | sha1sum -c - \
    && apt-get update \
    && apt-get -y install --no-install-recommends ./odoo.deb \
    && rm -rf /var/lib/apt/lists/* odoo.deb

# Install barcode font
COPY pfbfer.zip /root/pfbfer.zip
RUN mkdir -p /usr/lib/python2.7/dist-packages/reportlab/fonts \
        && unzip /root/pfbfer.zip -d /usr/lib/python2.7/dist-packages/reportlab/fonts/

# Generate British locales, as this is who we mostly serve
RUN locale-gen en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB:en
ENV LC_ALL en_GB.UTF-8

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /

# This custom entypoint augments the environment variables and the command line, and then despatches to the upstream /entrypoint.sh
COPY ./opusvl-entrypoint.py /
COPY ./odoo.conf /etc/odoo/

RUN chown odoo /etc/odoo/odoo.conf
RUN chmod a+rx /opusvl-entrypoint.py

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /var/lib/odoo \
        && chown -R odoo /var/lib/odoo
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
RUN mkdir /mnt/extra-addons-bundles \
        && chmod -R 755 /mnt/extra-addons-bundles

VOLUME ["/var/lib/odoo"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Set default user when running the container
USER odoo

ENTRYPOINT ["/opusvl-entrypoint.py"]

ONBUILD USER root
ONBUILD COPY ./addon-bundles/ /mnt/extra-addons-bundles/
ONBUILD RUN chmod -R u=rwX,go=rX /mnt/extra-addons-bundles
# If copy of build-hooks breaks your build:
#  mkdir build-hooks
#  touch build-hooks/.gitkeep
#  git add build-hooks/.gitkeep
# Introducing a directory for hooks means we can add more in
# future and allow you to add your own helper scripts without
# breaking the build again.
ONBUILD COPY ./build-hooks/ /root/build-hooks/
ONBUILD COPY ./requirements.txt /root/
ONBUILD RUN \
    pre_pip_hook="/root/build-hooks/pre-pip.sh" ; \
    if [ -f "$pre_pip_hook" ] ; \
    then \
        /bin/bash -x -e "$pre_pip_hook" \
            # reduce size of layer - probably last time we'll install anything using apt anyway \
            && rm -rf /var/lib/apt/lists/* \
            ; \
    fi
ONBUILD RUN pip3 install -r /root/requirements.txt
# Remove compiler for security in production
# ONBUILD RUN apt-get -y autoremove gcc g++
