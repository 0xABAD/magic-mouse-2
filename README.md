Overview
========

These are my notes for getting Apple's Magic Mouse 2 with _**scrolling when connected**_
to work with Linux.  While I'm running Ubuntu 19.04 this should work with other distro's
at it only involves `udev` which is standard with any modern Linux kernel.

**DISCLAIMER**: While I've used Linux off an on over the years, I am by no means an
  expert.  I managed to get the Magic Mouse 2 working for *me* it might not work for
  *you*, and I most likely will not be able to assist you.  Finally, while these
  instructions merely add a configuration file and shell script to your system, I take no
  responsibility for any damage that may occur on yours.  As with anything you find on the
  internet... **USE AT YOUR OWN RISK**.


Requirements
------------

Apple's Magic Mouse 1 works with Ubuntu out of the box (I tried with a co-worker's), Magic
Mouse 2 on the hand does not work completely (no scrolling) as it speaks a different
protocol.  Thankfully, someone has written a working driver that you can get from here:

[Linux Magic Mouse 2 Driver](https://github.com/rohitpid/Linux-Magic-Trackpad-2-Driver)

From those instructions, you don't need DKMS nor do you need to run the `install.sh`
script.  Instead just build the kernel module:

```
cd Link-Magic-Trackpad-2-Driver/linux/drivers/hid
make clean
make
```

Note that the repository will then have you unload the existing driver and load the one
you just built which will cause your Magic Mouse 2 to work as intended.  However, if you
disconnect the mouse, reboot, reset bluetooth, etc. the driver will not be reloaded.  I
thought I would be clever and replace the existing driver on my system with this new one
but everytime I reconnected the mouse the scrolling would not work and I would still have
to manually reload the driver.


The Fix
-------

The work-around listed here is definitely a kludge and uses `udev` to run a script when
the Magic Mouse 2 is connected via bluetooth.  I would recommend checking out this
tutorial about [udev rules](http://reactivated.net/writing_udev_rules.html) along with
reading the man pages.  Note that the tutorial is a bit old in internet years and refers
to tools `udevinfo`, `udevtest`, `udevcontrol`, and `udevtrigger`.  These should be
replaced with `udevadm info`, `udevadm test`, `udevadm control`, and `udevadm trigger`
respectively.  The `udevadm` command is pretty handy and you should definitely check out
the man page for it.

The first thing to do is learn how to identify the Magic Mouse when it is connected.  We
can look at the output of `tail -f ~/.local/share/xorg/Xorg.0.log` while connecting the
Magic Mouse 2 via Bluetooth and look for lines similiar to these:

```
[  3821.555] (II) config/udev: Adding input device Magic Mouse 2 (/dev/input/mouse3)
[  3821.555] (II) No input driver specified, ignoring this device.
[  3821.555] (II) This device may have been added with another device file.
[  3821.686] (II) config/udev: Adding input device Magic Mouse 2 (/dev/input/event21)
[  3821.686] (**) Magic Mouse 2: Applying InputClass "libinput pointer catchall"
[  3821.686] (**) Magic Mouse 2: Applying InputClass "Magic Mouse 2"
[  3821.686] (II) Using input driver 'libinput' for 'Magic Mouse 2'
```

The important line here is the `config/udev: Adding input device Magic Mouse 2
(/dev/input/event21)` or more specifically the `/dev/input/event21` part.  This acutal
location may differ on your system.  With this piece of information you can lookup the
mouse's physical ID with `udevadm info -a -p $(udevadm info -q path -n
/dev/input/event21)`.  This will print out a lot of info but important part will look
similiar to:

```
looking at parent device '//devices/pci0000:00/0000:00:14.0/usb1/1-6/1-6:1.0/bluetooth/hci0/hci0:2$6/0005:004C:0269.0013/input/input654':
    KERNELS=="input654"
    SUBSYSTEMS=="input"
    DRIVERS==""
    ATTRS{name}=="Magic Mouse 2"
    ATTRS{phys}=="d0:c6:37:e4:5f:fb"
    ATTRS{uniq}=="98:46:0a:ab:e2:e7"
    ATTRS{properties}=="0"
```

It's the `ATTRS{phys}=="d0:c6:37:e4:5f:fb"` (your ID may differ) that will be used in a
`udev` rule to identify the mouse inside a rule in the `/etc/udev/rules.d` directory.  In
that directory create a `10-magicmouse.rules` file and add the following:

```
SUBSYSTEMS=="input", \
    ATTRS{phys}=="d0:c6:37:e4:5f:fb", \
    ACTION=="add", \
    SYMLINK+="input/magicmouse", \
    RUN+="/home/user_name/path/to/magic-mouse-2-add.sh"
```

The `10-` prefix was picked arbitrarily and could be any number as it is used to determine
the lexical ordering of rules in the kernel.  The earlier the file is loaded guarantees
that the rule will be applied before any others.  Ensure that the `ATTRS{phys}` contains
the correct ID found from earlier and ensure that the `RUN+=` portion contains an
_**absolute**_ path to a script on your system.  Don't use a relative path or `~` as the
path is not interpreted by a shell and `udev` processes the path under root.  With that
place a shell script can be created at that location and should contain the following:

```
#!/bin/sh

reload() {
    modprobe -r hid_magicmouse
    insmod /home/user_name/path/to/Linux-Magic-Trackpad-2-Driver/linux/drivers/hid/hid-magicmouse.ko \
           scroll_acceleration=1 \
           scroll_speed=43 \
           middle_click_3finger=1
}

reload &
```

Replace the `/home/user_name/path/to` with the location of where you downloaded and built
the Magic Mouse 2 driver.  You can also adjust the scroll_speed to a value of your liking
(somewhere between 0 to 63).  If you wish to disable scroll acceleration or middle
clicking with 3 fingers then set those values to zero.  When this script is run it will
unload the default Magic Mouse driver and then load the new one built eariler.

Now we need to reload the `udev` database with:

```
sudo udevadm control -R
```

With that in place the Magic Mouse 2 will now be properly loaded with scrolling when
connected via Bluetooth.  Note that isn't perfect and sometimes the kernel will attempt to
reload the driver several times and may a few seconds.  Also, your mouse may randomly
disconnect at times but this was happening to me before applying this fix, may be
related to a kernel battery power management issue, and something I am looking into.
