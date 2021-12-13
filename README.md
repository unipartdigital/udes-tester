# UDES automated unit test runner

[![Build Status](https://travis-ci.org/unipartdigital/udes-tester.svg?branch=14.0)](https://travis-ci.org/unipartdigital/udes-tester)

This is an adaptation of
[`unipartdigital/odoo-tester:14.0`](https://github.com/unipartdigital/odoo-tester),
modified to use the [UDES fork](https://github.com/unipartdigital/odoo/tree/udes-14.0)
of the Odoo source repository and to preinstall various Python
packages and Odoo modules that are required in order to run UDES.

The resulting container is published on Docker Hub as
[`unipartdigital/udes-tester:14.0`](https://hub.docker.com/r/unipartdigital/udes-tester/).
