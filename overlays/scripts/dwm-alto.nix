{ writers }:
writers.writeBashBin "dwm-alto.sh" ''

  ID=`xdotool search --class dwmalto`
  if ! [[ -z $ID ]];
  then
    if xdotool search --onlyvisible --class dwmalto;
    then
      xdotool windowunmap $ID
    else
      xdotool windowmap $ID
    fi
  else
    st -c dwmalto -e tmux
  fi 
''
