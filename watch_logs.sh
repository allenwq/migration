#!/bin/sh
watch -n 0.5 tail -n 1 `find ../../../log -name 'course*.log' | xargs ls -tr | tail -n 8`
