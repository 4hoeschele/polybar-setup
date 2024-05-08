#!/bin/bash

# Define the laptop screen (update according to your setup)
LAPTOP_SCREEN="eDP"

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Function to get the lid status
get_lid_status() {
  grep -i "open" /proc/acpi/button/lid/LID/state >/dev/null && echo "open" || echo "closed"
}

# Get the lid status
LID_STATUS=$(get_lid_status)

# Log the lid status for debugging
echo "Lid status: $LID_STATUS"

# Handle screen configuration dynamically
if type "xrandr"; then
  # Detect external monitors dynamically
  external_monitors=$(xrandr --query | grep " connected" | grep -v "$LAPTOP_SCREEN" | cut -d" " -f1)

  # Log detected external monitors for debugging
  echo "External monitors: $external_monitors"

  if [[ "$LID_STATUS" == "closed" ]] && [ -n "$external_monitors" ]; then
    # If the lid is closed and external monitors are connected
    primary_monitor=$(echo "$external_monitors" | head -n 1)
    xrandr --output "$primary_monitor" --primary --auto --output "$LAPTOP_SCREEN" --off
    echo "Disabling laptop screen ($LAPTOP_SCREEN) and setting $primary_monitor as primary"
    for m in $external_monitors; do
      MONITOR=$m polybar --reload bar &
      echo "Launching Polybar on monitor: $m"
    done
  else
    # If the lid is open or no external monitors are connected
    if [ -n "$external_monitors" ]; then
      primary_monitor=$(echo "$external_monitors" | head -n 1)
      xrandr --output "$primary_monitor" --primary --auto --right-of "$LAPTOP_SCREEN" --output "$LAPTOP_SCREEN" --auto
      echo "Enabling laptop screen ($LAPTOP_SCREEN) with $primary_monitor as primary and extending to the right"
      for m in $external_monitors; do
        MONITOR=$m polybar --reload bar &
        echo "Launching Polybar on monitor: $m"
      done
      MONITOR=$LAPTOP_SCREEN polybar --reload bar &
      echo "Launching Polybar on laptop screen: $LAPTOP_SCREEN"
    else
      # No external monitors, enable the laptop screen
      xrandr --output "$LAPTOP_SCREEN" --auto --primary
      MONITOR=$LAPTOP_SCREEN polybar --reload bar &
      echo "Enabling laptop screen ($LAPTOP_SCREEN) as primary"
    fi
  fi
else
  polybar --reload bar &
  echo "xrandr not available, launching Polybar on all monitors"
fi
