#!/bin/bash -e

# The systemctl service-disable list moved into pi-videoreg's vrg-install
# ("SYSTEM SERVICE TWEAKS" step), which 91-videoreg invokes with --yes.
# vrg-install only *disables* cloud-init (reversible on a live system); here we
# additionally purge it so it is removed from the image entirely.
on_chroot << EOF
  apt-get purge -y cloud-init
  apt-get autoremove -y

  rm -rf /etc/cloud/
  rm -rf /var/lib/cloud/
EOF
