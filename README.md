This [Dracut ][dracut] module (dracut-serial) improves serial
access to initramfs early userspace. With it enabled it's
possible to unlock encrypted devices or deal with the emergency
shell over a serial connection in addition to the system console.

2018, Georg Sauthoff <mail@gms.tf>, GPLv3+

## Problem

Dracut-serial solves the following problem: as of Fedora
28/CentOS 7, the [Dracut][dracut] early userspace just uses
`/dev/console` for password prompting and starting the emergency
shell. Thus, one can enable the serial console by adding
something like

    console=tty0 console=ttyS0,115200

to the kernel commandline, but this means that `/dev/console` is
connected to `/dev/ttyS0` and thus the emergency shell is only
started on the serial console. The story is similar for unlocking
encrypted devices, i.e. `systemd-tty-ask-password-agent` is just
started on `/dev/console` (or via [Plymouth][plymouth] - cf.
`systemd-ask-password-plymouth.service` vs.
`systemd-ask-password-console.service` ).

Note that `/dev/console` is whatever [console declaration comes
last][kernel] at the kernel commandline, i.e. with

    console=ttyS0,115200 console=tty0

the Dracut emergency shell is started on the system console
instead of serial one. Log messages still go to both consoles.

This is suboptimal, as there is no backup console in case the
primary one fails or is unavailable. It's also kind of unexpected
as it's possible to enable both system and serial console with
[Grub2][grub2] and [late userspace][late] deals with multiple console as
a core feature.

See also [Fedora Bug 1031015  dracut shell doesn't start
(2013)][bug1031015].

## Solution

Dracut-serial  includes a [getty][getty] (`agetty`) to start the dracut emergency
shell (i.e. `/bin/dracut-emergency`) on `/dev/ttyS0, as well. It
overrides the `dracut-emergency.service` such that it always
uses `/dev/tty0`. In that way both services are independent of
the ordering of `console=` kernel commandline parameters and
there is always a backup console available. I still makes sense
to add `console=` parameters to get log messages on all consoles
and to configure serial connection parameters (like baud).

Dracut-serial although starts the password prompting agent
(`/usr/bin/systemd-tty-ask-password-agent` via
`systemd-ask-password-serial.service`) on the serial console such
that one is able to unlock encrypted devices either via the
system or the serial console.

## Install

Copy the `46sshd` subdirectory to the [Dracut][dracut] module directory:

    # cp -ri 05serial /usr/lib/dracut/modules.d

Regenerate the initramfs:

    # dracut -f -v

Verify that this `sshd` module is included. Either via inspecting the verbose
output or via `lsinitrd`. Reboot.


## Emergency Shell

In the current design, leaving the emergency shell on the serial
console yields a restart of that shell. Thus, to resume the
system boot one has to explicitly terminate the emergency shell
service, e.g.:

    $ systemctl stop dracut-emergency.service

As before, leaving the emergency shell on the system console
automatically resumes the boot.

A `systemctl kill ...` may also be used to terminate the
emergency service, although one has to explicitly specify SIGHUP
on CentOS 7 (`systemctl kill --signal=HUP ...`) to get the shell
terminated.

As always, a simple way to unconditionally entering the emergency
shell is to add `rd.break` to the kernel commandline.


## Space Overhead

The `agetty` utility is very small:

    System       file size
    ----------------------
    CentOS 7     37 KiB
    Fedora 27    57 KiB
    Fedora 28    63 KiB


## Development Notes

Dracut starts the `dracut-emergency.service` via
`_emergency_shell()` in `lib/dracut-lib.sh`.

The Dracut module `dracut-systemd` (under `98dracut-systemd`)
contains the `dracut-emergency.service` and pulls the
`systemd-ask-password-{console,plymouth}.*` service files from
the system.


## Tested Environments

- Fedora 28
- Fedora 27
- CentOS 7

[bug1031015]: https://bugzilla.redhat.com/show_bug.cgi?id=1031015#c5
[dracut]: https://dracut.wiki.kernel.org/index.php/Main_Page
[getty]: https://en.wikipedia.org/wiki/Getty_(Unix)
[grub2]: https://www.coreboot.org/Serial_console#GRUB2
[kernel]: https://www.kernel.org/doc/html/v4.15/admin-guide/serial-console.html
[late]: http://0pointer.de/blog/projects/serial-console.html
[plymouth]: http://www.freedesktop.org/wiki/Software/Plymouth
