FROM unipartdigital/odoo-tester

# Packages
#
RUN dnf install -y python3-paramiko python3-ply python3-xlwt ; \
    dnf clean all

# UDES Odoo snapshot
#
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
