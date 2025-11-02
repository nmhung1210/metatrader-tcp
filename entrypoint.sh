#!/bin/bash

xvfb-run --auto-servernum --server-args="-screen 0 8x8x8" wine /app/app.exe
