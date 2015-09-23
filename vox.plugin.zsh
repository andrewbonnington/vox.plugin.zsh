# ------------------------------------------------------------------------------
#          FILE:  vox.plugin.zsh
#   DESCRIPTION:  oh-my-zsh plugin file to control Vox.
#        AUTHOR:  Andrew Bonnington (https://github.com/andrewbonnington)
#       VERSION:  1.0
# ------------------------------------------------------------------------------

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
    -v|--version)
      print "1.0"
      return 1
      ;;
    ""|-h|--help)
      echo "Usage: vox <option>"
      echo "\t-h, --help\tShow this message, then exit"
      echo "\t-v, --version\tShow version number, then exit"
      echo "\nOption:"
      echo "\tlaunch|quit\t\tLaunch or quit VOX"
      echo "\tplay|pause\t\tPlay or pause the current track"
      echo "\trewind|forward\t\tSkip back or ahead in the current track"
      echo "\tfastrewind|fastforward\tSkip further back or ahead in the current track"
      echo "\tnext|previous|resume\tPlay the next or previous track"
      echo "\tvol|volume [up|down]\tIncrease or decrease the volume"
      return 0
      ;;
    *)
      print "Unknown option: $opt"
      return 1
      ;;
  esac
  osascript -e "tell application \"VOX\" to $opt"
}
