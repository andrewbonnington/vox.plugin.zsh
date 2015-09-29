# ------------------------------------------------------------------------------
#          FILE:  vox.plugin.zsh
#   DESCRIPTION:  oh-my-zsh plugin file to control Vox.
#        AUTHOR:  Andrew Bonnington (https://github.com/andrewbonnington)
#       VERSION:  1.3.0
# ------------------------------------------------------------------------------

function _vox_track_info() {
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

function _vox_get_volume() {
  local vol=$(
    osascript 2>/dev/null <<EOF
      tell application "VOX" to set vol to player volume

      set vol2 to round (vol / 10)

      if vol is not 0 and vol2 is 0 then set vol2 to 0.1

      return vol2
EOF
  )
  echo "$vol"
}

function _vox_set_volume() {
  if [ "$1" -ge 0 -a "$1" -le 10 ]
  then
    local curr_vol=$( _vox_get_volume )

    if [ "$1" = 0 ]
    then
      if [ "$curr_vol" -gt 0 ]
      then
        _vox_kill_volume
      fi
      return 0
    fi

    if [ "$curr_vol" = 0.1 ]
    then
      curr_vol=0
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
     return 1
  fi
}

function _vox_kill_volume() {
  local vol=$( _vox_get_volume )

  osascript 2>/dev/null <<EOF
    set vol to $vol

    if vol > 0 then
      set volSteps to vol + 1
      
      repeat volSteps times
        tell application "VOX" to decreaseVolume
      end repeat
    end if
EOF
}

function _vox_mute() {
  local vol=$( _vox_get_volume )

  if [ "$vol" -gt 0 ]
  then
    if [ "$vol" = 0.1 ]
    then
      vol="1" 
    fi
    echo "$vol" > /tmp/voxvol.dat
    _vox_kill_volume
  else
    print "VOX is already muted"
  fi
}

function _vox_unmute() {
  local vol=$( _vox_get_volume )

  if [ "$vol" = 0 ]
  then
    if [ -f "/tmp/voxvol.dat" ]
    then
      vol=`cat /tmp/voxvol.dat`
      _vox_set_volume "$vol"
    else
      print "VOX isn't muted"
    fi
  fi
}

function _vox_resume() {
  osascript 2>/dev/null <<EOF
    tell application "VOX" to set the state to player state

    if state is 0 then
      tell application "VOX" to play
    end if
EOF
}

function vox() {
  local opt=$1
  case "$opt" in
    launch|play|pause|next|previous|quit)
      ;;
    resume)
      _vox_resume
      return 0
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
        [0-9]|10)
          _vox_set_volume "$state"
          return 0
          ;;
        ""|*)
          print "Usage: vox vol|volume [up|down] or vox vol|volume [0-10]. Invalid option."
          return 1
          ;;
        esac
      ;;
    mute)
      _vox_mute
      return 0
      ;;
    unmute)
      _vox_unmute
      return 0
      ;;
    status)
      _vox_track_info
      return 0
      ;;
    -v|--version)
      print "1.3.0"
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
      echo "\tvol|volume #\t\tSet volume to # [0-10]"
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
