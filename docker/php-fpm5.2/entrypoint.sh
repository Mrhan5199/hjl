#!/bin/bash
/etc/init.d/httpd start
tail -F /var/log/httpd/access_log
