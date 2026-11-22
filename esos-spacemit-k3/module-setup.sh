#!/bin/bash

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_simple /usr/lib/esos/rt24_os0_rcpu.elf /lib/firmware/rt24_os0_rcpu.elf
    inst_simple /usr/lib/esos/rt24_os1_rcpu.elf /lib/firmware/rt24_os1_rcpu.elf
}
