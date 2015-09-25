# ------------------------------------------------------------------------------
#          FILE:  vox.plugin.zsh
#   DESCRIPTION:  oh-my-zsh plugin file to control Vox.
#        AUTHOR:  Andrew Bonnington (https://github.com/andrewbonnington)
#       VERSION:  1.1.0
# ------------------------------------------------------------------------------

function _track_info() {
  local info="$(
    osascript 2>/dev/null <<EOF
      tell application "VOX"
        set trackname to track
        set artistname to artist
        set albumname to album
        set state to player state
      end tell

      if artistname = missing value then
        set artistname to ""
      else
        set artistname to " – " & artistname
      end if

      if albumname = missing value then
        set albumname to ""
      else
        set albumname to " (" & albumname & ")"
      end if

      if state is 1 then
        return "Now Playing: " & trackname & artistname & albumname
      else
        return "VOX is currently paused"
      end if
EOF
  )"
  echo "$info"
}

function _get_volume() {
  local vol=$(
    osascript 2>/dev/null <<EOF
      on ceil(x)
        set y to 0
        
        if x > 0 then
          set y to (x div 1) + 1
        else if x < 0 then
          set y to x div 1
        end if
        
        return y
      end ceil

      tell application "VOX" to set vol to player volume

      if vol mod 10 is not 0 then
        set vol to ceil(vol / 10) * 10
      end if

      return vol div 10
EOF
  )
  echo "$vol"
}

function _set_volume() {
  if [ "$1" -ge 0 -a "$1" -le 10 ]
  then
    local curr_vol=$( _get_volume )

    if [ "$1" = 0 ]
    then
      if [ "$curr_vol" -gt 0 ]
      then
        _kill_volume
      fi
      return 0
    fi

    osascript 2>/dev/null <<EOF
      set currVol to $curr_vol
      set vol to $1

      if vol > 10 then set vol to 10
      if vol < 0 then set vol to 0
      
      if currVol = vol then return
      
      if currVol > vol then
        set volSteps to currVol - vol
        
        repeat volSteps times
          tell application "VOX" to decreaseVolume
        end repeat
      else
        set volSteps to vol - currVol
        
        repeat volSteps times
          tell application "VOX" to increasVolume
        end repeat
      end if
EOF
  else
     print "Value must be between 0 and 10."
  fi
}

function _kill_volume() {
  local vol=$( _get_volume )

  osascript 2>/dev/null <<EOF
    set vol to $vol

    if vol > 0 then
      set volSteps to vol
      
      repeat volSteps times
        tell application "VOX" to decreaseVolume
      end repeat
    end if
EOF
}

function _mute() {
  local vol=$( _get_volume )

  if [ "$vol" -gt 0 ]
  then
    echo "$vol" > /tmp/voxvol.dat
    _kill_volume
  else
    print "VOX is already muted"
  fi
}

function _unmute() {
  local vol=$( _get_volume )
  
  if [ "$vol" = 0 ]
  then
    if [ -f "/tmp/voxvol.dat" ]
    then
      vol=`cat /tmp/voxvol.dat`
      _set_volume "$vol"
    else
      print "VOX isn't muted"
    fi
  fi
}

function vox() {
  local opt=$1
  case "$opt" in
    launch|play|pause|next|previous|quit)
      ;;
    resume)
      opt="play"
      ;;
    rewind)
      opt="rewindBackward"
      ;;
    fastrewind)
      opt="rewindBackwardFast"
      ;;
    forward)
      opt="rewindForward"
      ;;
    fastforward)
      opt="rewindForwardFast"
      ;;
    vol|volume)
      local state=$2
      case "$state" in 
        down)
          opt="decreaseVolume"
          ;;
        up)
          opt="increasVolume"
          ;;
        ""|*)
          print "Usage: vox vol|volume [up|down]. Invalid option."
          return 1
          ;;
        esac
      ;;
    mute)
      _mute
      return 0
      ;;
    unmute)
      _unmute
      return 0
      ;;
    status)
      _track_info
      return 0
      ;;
    -v|--version)
      print "1.2.0"
      return 0
      ;;
    ""|-h|--help)
      echo "Usage: vox <option>"
      echo "\t-h, --help\tShow this message, then exit"
      echo "\t-v, --version\tShow version number, then exit"
      echo "\nOptions:"
      echo "\tlaunch|quit\t\tLaunch or quit VOX"
      echo "\tplay|pause|resume\tPlay or pause the current track"
      echo "\trewind|forward\t\tSkip back or ahead in the current track"
      echo "\tfastrewind|fastforward\tSkip further back or ahead in the current track"
      echo "\tnext|previous\t\tPlay the next or previous track"
      echo "\tvol|volume [up|down]\tIncrease or decrease the volume"
      echo "\tmute|unmute\t\tToggle volume"
      echo "\tstatus\t\t\tShow current track details"
      return 0
      ;;
    *)
      print "Unknown option: $opt"
      return 1
      ;;
  esac
  osascript -e "tell application \"VOX\" to $opt"
}
