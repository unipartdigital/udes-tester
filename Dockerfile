FROM unipartdigital/odoo-tester

# Distro packages
#
RUN dnf install -y fedora-workstation-repositories dnf-plugins-core ; \
    dnf config-manager --set-enabled google-chrome ; \
    dnf install -y python3-paramiko python3-ply python3-click \
		   python3-selenium google-chrome-stable \
		   xorg-x11-server-Xvfb cups-pdf xorg-x11-fonts-Type1 \
		   xorg-x11-fonts-75dpi python3-requests python3-shortuuid \
           python3-pyicu; \
    dnf clean all

# Non-distro packages
#
USER odoo
RUN pip3 install --user odoorpc "pyyaml<5.1"

## Download a compatible version of chromedriver
## TODO (ssb): this is temporary, remove this block and use dnf when the distro version is up to date.
USER root
ADD https://chromedriver.storage.googleapis.com/74.0.3729.6/chromedriver_linux64.zip /bin/chromedriver.zip
RUN unzip -d /bin /bin/chromedriver.zip
RUN chmod a+x /bin/chromedriver

# UDES Odoo snapshot
#
USER root
ADD https://codeload.github.com/unipartdigital/odoo/zip/udes-${ODOO_VERSION} \
    /opt/odoo.zip
RUN rm -rf /opt/odoo /opt/odoo-${ODOO_VERSION} \
	   /opt/odoo-udes-${ODOO_VERSION} ; \
    unzip -q -d /opt /opt/odoo.zip ; \
    ln -s odoo-udes-${ODOO_VERSION} /opt/odoo

# Prerequisite module installation (without tests)
#
RUN odoo-wrapper --without-demo=all -i \
    project,document,product,stock,stock_picking_batch,purchase,mrp
