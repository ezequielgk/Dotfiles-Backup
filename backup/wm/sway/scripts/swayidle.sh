#!/bin/bash

killall swayidle 2>/dev/null

swayidle -w \
    timeout 1800 'systemctl suspend'
