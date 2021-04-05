#!/bin/sh

pgrep swayidle &> /dev/null && echo "idle on" || echo "idle off"
