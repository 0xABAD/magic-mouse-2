#!/bin/sh

reload() {
    modprobe -r hid_magicmouse
    insmod /home/dan/.local/lib/modules/5.0.0-27-generic/extra/hid-magicmouse.ko \
           scroll_acceleration=1 \
           scroll_speed=43 \
           middle_click_3finger=1
}

reload &
