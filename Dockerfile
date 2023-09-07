FROM ubuntu:22.04

# NOTE: This image is no longer based on unipartdigital/odoo-tester:14.0
# and those directives have been bundled into this image.

ARG DEBIAN_FRONTEND=noninteractive
# Odoo version
#
ENV ODOO_VERSION 14.0

# System packages
USER root
RUN apt update -y
RUN apt install -y \
    build-essential \
    curl \
    gcc \
    git \
    libffi-dev \
    libldap2-dev \
    libncurses5-dev \
    libpq-dev \
    libsasl2-dev \
    libssl-dev \
    libxml2-dev \
    libxslt-dev \
    nodejs \
    npm \
    openssl \
    postgresql \
    postgresql-client \
    printer-driver-cups-pdf \
    python3 \
    python3-pip \
    python3-pkg-resources \
    python3-setuptools \
    unzip \
    wget \
    wkhtmltopdf \
    x11vnc \
    xfonts-75dpi \
    xvfb \
    zlib1g \
    zlib1g-dev

# Odoo requires a non-standard build of wkhtmltopdf for many use cases
# (including running without a local X display).
#
ENV H2P_BASE https://github.com/wkhtmltopdf/packaging/releases/download
ENV H2P_VER 0.12.6
ENV H2P_REL 1
ENV H2P_FILE wkhtmltox_${H2P_VER}-${H2P_REL}.bionic_amd64.deb
ENV H2P_URI ${H2P_BASE}/${H2P_VER}-${H2P_REL}/${H2P_FILE}
# wkhtmltopdf deb dependency (no longer in package manager)
ENV LIBSSL_FILE libssl1.1_1.1.1f-1ubuntu2_amd64.deb
ENV LIBSSL_URI http://security.ubuntu.com/ubuntu/pool/main/o/openssl/${LIBSSL_FILE}
# Chrome deb
ENV CHROME_FILE google-chrome-stable_current_amd64.deb
ENV CHROME_URI https://dl.google.com/linux/direct/${CHROME_FILE}

# Download and install all the deb packages manually
# using apt install rather than dpkg -i so dependencies resolve
RUN wget ${CHROME_URI} && \
    apt install -y ./${CHROME_FILE} && \
    rm ./${CHROME_FILE}

RUN wget ${LIBSSL_URI} && \
    apt install -y ./${LIBSSL_FILE} && \
    rm ./${LIBSSL_FILE}

RUN wget ${H2P_URI} && \
    dpkg -i ./${H2P_FILE} && \
    rm ./${H2P_FILE}

## Install chromedriver
#
# Exports only persist in a single run directive, so we have to do this in one line.
# Strip build version number on the first endpoint, as chromedriver version can lag behind slightly
# This gives us the format for the latest compatible chromedriver in the second endpoint.
RUN export CHROME_VER=$(echo $(google-chrome --version) | grep -oE '([[:digit:]]+\.)+' | sed 's/.$//') \
    && export CHROMEDRIVER_VER=$(curl --location --fail --retry 3 https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_$CHROME_VER) \
    && curl --silent --show-error --location --fail --retry 3 --output /bin/chromedriver-linux64.zip "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/$CHROMEDRIVER_VER/linux64/chromedriver-linux64.zip" \
    && unzip -d /bin /bin/chromedriver-linux64.zip \
    && mv /bin/chromedriver-linux64/chromedriver /bin/chromedriver \
    && chmod a+x /bin/chromedriver

# PostgreSQL initialisation & tuning
#
ENV PGDATA /var/lib/postgresql/14/main
USER postgres
COPY postgresql.conf.nosync ${PGDATA}/postgresql.conf.nosync
RUN cat ${PGDATA}/postgresql.conf.nosync >> ${PGDATA}/postgresql.conf

# Odoo user and database
#
USER root
RUN useradd odoo -m
USER postgres
RUN service postgresql start ; \
    createuser odoo ; \
    createdb --owner odoo odoo ; \
    service postgresql stop

# Odoo wrapper script
#
USER root
RUN mkdir /opt/odoo-addons
COPY odoo-wrapper /usr/local/bin/odoo-wrapper

# UDES Odoo snapshot
#
ADD https://codeload.github.com/unipartdigital/odoo/zip/udes-${ODOO_VERSION} \
    /opt/odoo.zip
RUN rm -rf /opt/odoo /opt/odoo-${ODOO_VERSION} \
           /opt/odoo-udes-${ODOO_VERSION} ; \
    unzip -q -d /opt /opt/odoo.zip ; \
    ln -s odoo-udes-${ODOO_VERSION} /opt/odoo

# Non-distro packages
#
USER odoo
RUN pip3 install --upgrade pip
RUN ls /opt/odoo
RUN pip3 install --user -r /opt/odoo/requirements.txt

# Remove packages which are no longer needed
#
USER root
RUN apt remove -y \
    libffi-dev \
    libldap2-dev \
    libncurses5-dev \
    libpq-dev \
    libsasl2-dev \
    libxml2-dev \
    libxslt-dev \
    zlib1g-dev

# Grant odoo user db create permission
#
USER postgres
RUN service postgresql start; \
    psql -c 'ALTER USER odoo WITH CREATEDB'; \
    service postgresql stop;
USER root

# Prerequisite module installation (without tests)
#
RUN odoo-wrapper --without-demo=all -i \
    project,document,product,stock,stock_picking_batch

# Entry point
#
ENTRYPOINT ["/usr/local/bin/odoo-wrapper"]
