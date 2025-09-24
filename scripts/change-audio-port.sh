#!/bin/bash

SINK=$(pactl get-default-sink)

CURRENT_PORT=$(pactl list sinks | grep -A 15 "Name: $SINK" | grep "Active Port" | awk -F': ' '{print $2}')

if [ "$CURRENT_PORT" = "analog-output-lineout" ]; then
    pactl set-sink-port "$SINK" analog-output-headphones
else
    pactl set-sink-port "$SINK" analog-output-lineout
fi
