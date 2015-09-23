# ------------------------------------------------------------------------------
#          FILE:  vox.plugin.zsh
#   DESCRIPTION:  oh-my-zsh plugin file to control Vox.
#        AUTHOR:  Andrew Bonnington (https://github.com/andrewbonnington)
#       VERSION:  1.1.0
# ------------------------------------------------------------------------------

function _now_playing_info() {
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

function vox() {
  local opt=$1
  case "$opt" in
    launch|play|pause|next|previous|quit)
      ;;
    resume)
      # Alias for play
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
    status)
      _now_playing_info
      return 0
      ;;
    -v|--version)
      print "1.1.0"
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
