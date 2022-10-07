{ writers }:
writers.writeBashBin "inc-volume.sh" ''
  pactl -- set-sink-volume "$(pactl -- get-default-sink)" +5%
  
  VOL="$(pamixer --get-volume)"
  notify-send -t 1000 -h int:value:$VOL "VOL:"
''
