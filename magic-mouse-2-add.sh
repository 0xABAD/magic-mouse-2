#!/bin/sh

reload() {
    modprobe -r hid_magicmouse
    insmod /home/dan/Code/Linux-Magic-Trackpad-2-Driver/linux/drivers/hid/hid-magicmouse.ko \
           scroll_acceleration=1 \
           scroll_speed=43 \
           middle_click_3finger=1
}

reload &
