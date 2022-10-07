{ writers }:
writers.writeBashBin "dec-volume.sh" ''
  pactl -- set-sink-volume "$(pactl -- get-default-sink)" -10%
  
  VOL="$(pamixer --get-volume)"
  notify-send -t 1000 -h int:value:$VOL "VOL:"
''
