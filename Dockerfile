FROM unipartdigital/odoo-tester

# Distro packages
#
RUN dnf install -y fedora-workstation-repositories dnf-plugins-core ; \
    dnf config-manager --set-enabled google-chrome ; \
    dnf install -y python3-paramiko python3-ply \
                   google-chrome-stable pipenv \
                   xorg-x11-server-Xvfb cups-pdf xorg-x11-fonts-Type1 \
                   xorg-x11-fonts-75dpi python3-shortuuid \
		   postgresql-contrib python3-paho-mqtt python3-ldap \
		   python3-cairo python3-qrcode; \
    dnf clean all

# Non-distro packages should be installed downstream to minimise image rebuilds.

## Download a compatible version of chromedriver
#
USER root
RUN export CHROME_VER=$(echo $(google-chrome --version) | grep -oE '([[:digit:]]+\.)+' | sed 's/.$//') \
    && echo $"Chrome Version: $CHROME_VER" && export CHROME_DRIVER_URL=$"https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_$CHROME_VER" \
    && echo $"Chrome URL: $CHROME_DRIVER_URL" \
    && export CHROMEDRIVER_VER=$(curl --show-error --location --fail --retry 3 $CHROME_DRIVER_URL) \
    && echo $"Chrome Driver Version: $CHROMEDRIVER_VER" \
    && curl --silent --show-error --location --fail --retry 3 --output /bin/chromedriver_linux64.zip "https://storage.googleapis.com/chrome-for-testing-public/$CHROMEDRIVER_VER/linux64/chromedriver-linux64.zip" \
    && unzip -d /bin /bin/chromedriver_linux64.zip \
    && chmod a+x /bin/chromedriver-linux64 \
    && mv /bin/chromedriver-linux64/chromedriver /bin/chromedriver \
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
    project,document,product,stock,stock_picking_batch,purchase,mrp
