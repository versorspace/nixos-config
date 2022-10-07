{ writers }:
writers.writeBashBin "dwm-screenshot.sh" ''

maim -s | tee ~/Pictures/$(date +%s).png | xclip -selection clipboard -t image/png
''
