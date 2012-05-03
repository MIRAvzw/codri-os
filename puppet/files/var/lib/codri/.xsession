#!/bin/sh
ratpoison &
pulseaudio --start &
codri-client
