#!/bin/bash
set -e

INT_PREFIX=eDP

function check_progs {
#Check existence of certain required programs
  PROGS="xrandr"
  for name in $PROGS; do
    if [ ! `which $name` ];then
      echo -e "*Program “$name” is not installed or not in PATH."
      exit 1
    fi
  done
}

function get_number_of_displays {
  local DISPLAY_COUNT=$(xrandr | grep " connected" | wc -l)
	echo "$DISPLAY_COUNT"
}

function grab_display {
  local DISP=$(xrandr |grep " connected" |grep ^$1 |cut -d ' ' -f1)
  echo "$DISP"
}

function grab_primary_display {
  local DISP=$(xrandr |grep " connected" |grep primary |cut -d ' ' -f1)
  echo "$DISP"
}

function grab_other_displays {
  local DISP=$(xrandr |grep " connected" |grep -v $1 |cut -d ' ' -f1)
  echo "$DISP"
}

function turn_off_display {
  echo "disabling $1"
  xrandr --output $1 --off
}

function turn_on_display {
  echo "enabling $1"
  xrandr --output $1 --auto
}

function turn_off_disconnected_displays {
	for name in $(xrandr |grep "disconnected" |cut -d ' ' -f1); do
		turn_off_display "$name"
	done
}

function gather_windows_if_possible {
	if [ `which gather_windows` ];then
		echo "gathering windows to primary screen"
		gather_windows
	fi
}

function turn_off_connected_displays {
	turn_off_display $EXT_DISP
	turn_off_display $INT_DISP
}

function setup_connected_displays {
# use this with <secondary_disp> <direction_of_secondary> <primary_disp>
    if [ $DISPLAY_COUNT -lt 2 ]; then
      echo "you don't have two displays"
      exit 1
    else
      echo "using $1 $2 $3(pri)"
			xrandr --output $1 --off
			# turn_off_connected_displays
			xrandr --output $3 --primary --auto
			xrandr --output $1 --noprimary --auto --$2 $3
    fi

}

check_progs
DISPLAY_COUNT=$(get_number_of_displays)
turn_off_disconnected_displays

INT_DISP=$(grab_display $INT_PREFIX)
EXT_DISP=$(grab_other_displays $INT_DISP)


case "$1" in
  int|internal)
    echo "using internal display"
    if [ $DISPLAY_COUNT -gt 1 ]; then
			turn_off_display $EXT_DISP
		fi	
    turn_on_display $INT_DISP
		gather_windows_if_possible
  ;;
  ext|external)
    echo "using external display"
    if [ $DISPLAY_COUNT -gt 1 ]; then
			turn_off_display $INT_DISP
		fi	
    turn_on_display $EXT_DISP
		gather_windows_if_possible
  ;;
  extprimary|ep|both)
			setup_connected_displays $INT_DISP right-of $EXT_DISP
  ;;
  extprimaryreverse|epr|bothalt)
			setup_connected_displays $INT_DISP left-of $EXT_DISP
  ;;
  intprimary|ip|classic)
			setup_connected_displays $EXT_DISP right-of $INT_DISP
  ;;
  intprimaryreverse|ipr|classicalt)
			setup_connected_displays $EXT_DISP left-of $INT_DISP
  ;;
  tp|toggle_primary)
    if [ $DISPLAY_COUNT -lt 2 ]; then
      echo "you don't have two displays"
      exit 1
    else
      CURRENT_PRIMARY=$(grab_primary_display)
      if [ "$CURRENT_PRIMARY" = "$INT_DISP" ]; then
        echo "setting $EXT_DISP as primary from $CURRENT_PRIMARY"
        xrandr --output $EXT_DISP --primary
      else 
        echo "setting $INT_DISP as primary from $CURRENT_PRIMARY"
        xrandr --output $INT_DISP --primary
      fi
			gather_windows_if_possible
    fi
  ;;
  *)
		echo "Usage: switch_displays.sh [int, ext, both, bothalt, classic, classicalt, tp]"
  ;;
esac

if [ $(ps -ef |grep synergy |wc -l) -gt 0 ]; then
	echo "synergy running - restarting"
	killall -9 synergyc
	synergyc -n e7440 dock
fi
