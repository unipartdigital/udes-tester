FROM unipartdigital/odoo-tester:14.0

# Distro packages
#
RUN dnf install -y fedora-workstation-repositories dnf-plugins-core ; \
    dnf config-manager --set-enabled google-chrome ; \
    dnf install -y python3-paramiko python3-ply \
                   google-chrome-stable pipenv \
                   xorg-x11-server-Xvfb cups-pdf xorg-x11-fonts-Type1 \
                   xorg-x11-fonts-75dpi python3-shortuuid python3-pyicu \
		   postgresql-contrib; \
    dnf clean all

# Non-distro packages
#
USER odoo
RUN pip3 install --user unittest-xml-reporting

## Download a compatible version of chromedriver
#
USER root
RUN export CHROME_VER=$(echo $(google-chrome --version) | grep -oE '([[:digit:]]+\.)+' | sed 's/.$//') \
    && export CHROMEDRIVER_VER=$(curl --location --fail --retry 3 https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VER) \
    && curl --silent --show-error --location --fail --retry 3 --output /bin/chromedriver_linux64.zip "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VER/chromedriver_linux64.zip" \
    && unzip -d /bin /bin/chromedriver_linux64.zip \
    && chmod a+x /bin/chromedriver


# UDES Odoo snapshot
#
USER root
ADD https://codeload.github.com/unipartdigital/odoo/zip/udes-${ODOO_VERSION} \
    /opt/odoo.zip
RUN rm -rf /opt/odoo /opt/odoo-${ODOO_VERSION} \
           /opt/odoo-udes-${ODOO_VERSION} ; \
    unzip -q -d /opt /opt/odoo.zip ; \
    ln -s odoo-udes-${ODOO_VERSION} /opt/odoo


USER postgres
RUN pg_ctl start; psql --dbname odoo -c "CREATE EXTENSION pg_trgm;"; pg_ctl stop;
USER root

# Prerequisite module installation (without tests)
#
RUN odoo-wrapper --without-demo=all -i \
    project,document,product,stock,stock_picking_batch
