#!/bin/bash

# 2018, Georg Sauthoff <mail@gms.tf>
# SPDX-License-Identifier: GPL-3.0-or-later

# called by dracut
check() {
    require_binaries agetty || return 1
    # 0 enables by default, 255 only on request
    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst agetty
    inst_simple "${moddir}/serial-emergency@.service" "$systemdsystemunitdir/serial-emergency@.service"
    inst_simple "${moddir}/dracut-emergency.service" "$systemdsystemconfdir/dracut-emergency.service"
    inst_simple "${moddir}/systemd-ask-password-serial.service" "$systemdsystemunitdir/systemd-ask-password-serial.service"
    systemctl --root "$initdir" enable serial-emergency@ttyS0.service
    systemctl --root "$initdir" enable systemd-ask-password-serial.service
    return 0
}

