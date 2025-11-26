#!/bin/bash

xvfb-run --auto-servernum --server-args="-screen 0 8x8x8" wine /app/app.exe > /dev/null 2>&1 &
sleep 10
tail -f /app/.sessions/logs/metatrader.log
