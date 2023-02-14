# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  
  # Make ready for nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.cleanTmpDir = true;

  boot.kernelParams = [ "psmouse.synaptics_intertouch=0" ];
  # boot.kernelModules = [ "snd_pcm_oss" ];

  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/etc/nixos/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
    "nixpkgs-overlays=/etc/nixos/overlays-compat/"
  ];

  nixpkgs.config.allowUnfree = true;
  # nixpkgs.overlays = [ (import ./overlays/default.nix) ];

  nixpkgs.overlays = [ (self: super: {
    # st = super.st.override {
    #   conf = builtins.readFile ./overlays/st/config.h;
    #   patches = [
    #     ./overlays/st/st-externalpipe-0.8.4.diff
    #     ./overlays/st/st-newterm-extpipecompat.diff
    #     ./overlays/st/st-scrollback-0.8.5.diff
    #     ./overlays/st/st-scrollback-mouse-20220127-2c5edf2.diff
    #     ./overlays/st/st-scrollback-mouse-altscreen-20220127-2c5edf2.diff
    #     ./overlays/st/st-alpha-20220206-0.8.5.diff
    #     ./overlays/st/st-anysize-20220718-baa9357.diff
    #     ./overlays/st/st-bold-is-not-bright-20190127-3be4cf1.diff
    #     ./overlays/st/st-ubuntu-0.8.5-alpha.diff
    #     ./overlays/st/st-boxdraw_v2.1-0.8.5.diff
    #     ./overlays/st/st-glyph-wide-support-boxdraw.diff
    #     ./overlays/st/st-font2-0.8.5.diff
    #     ./overlays/st/st-externalpipe-eternal-0.8.3.diff
    #     ./overlays/st/7672445bab01cb4e861651dc540566ac22e25812.diff
    #     ./overlays/st/st-autocomplete-0.8.5.diff
    #     # ./overlays/st/st-0.8.5-autocomplete-20220327-230120.diff
    #     # ./overlays/st/st-scrollback-reflow-0.8.5v2.diff
    #     # ./overlays/st/st-fontpatch-0.8.5.diff
    #     # ./overlays/st/st-focus-0.8.5-patch_alpha.diff
    #   ];
    # };

    # vimPlugins.borlandp-vim = super.buildVimPluginFrom2Nix {
    #   pname = "borlandp-vim";
    #   version = "2022-05-10";
    #   src = super.fetchFromGitHub {
    #     owner = "caglartoklu";
    #     repo = "borlandp.vim";
    #     rev = "c75eb984a26b507fa0d7b4ae5ff3bf4451daa51f";
    #     sha256 = "0p6riwjygs313yh0shc57yz2qp3416z5d8nvcq58n521q79lbn2g";
    #   };
    #   meta.homepage = "";
    # };

    # dwm = super.dwm.override {
    #   patches = [
    #     ./overlays/dwm/dwm-cool-autostart-6.3.diff
    #     ./overlays/dwm/dwm-moveresize-6.2.diff
    #     ./overlays/dwm/dwm-fullgaps-6.3.diff
    #   ];
    #   conf = builtins.readFile ./overlays/dwm/config.h;
    # };

    # tabbed = super.tabbed.override {
    #   customConfig = builtins.readFile ./overlays/tabbed/config.h;
    #   patches = [ ./overlays/tabbed/alpha.diff ];
    # };

    slstatus = super.slstatus.override {
      conf = builtins.readFile ./overlays/slstatus/config.h;
    };

    dwm-alto = super.writers.writeBashBin "dwm-alto.sh" ''
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
    	tabbed -c -n dwmalto st -w
    fi
    '';

    dwm-screenshot = super.writers.writeBashBin "dwm-screenshot.sh" ''
    maim -s | xclip -selection clipboard -t image/png
    FNAME="$(date '+%s').png"
    xclip -o -selection clipboard > "$HOME/Pictures/$FNAME"
    xclip -o -selection clipboard | tesseract stdin stdout | grep -v '^$' | xclip -i"
    xclip -o > "$HOME/Pictures/.''${FNAME}.txt"
    notify-send -t 1000 "OCRed: $(xclip -o)"
    '';

    inc-volume = super.writers.writeBashBin "inc-volume.sh" ''
    pactl -- set-sink-volume "$(pactl -- get-default-sink)" +5%
    VOL="$(pamixer --get-volume)"
    notify-send -t 1000 -h int:value:$VOL "VOL:"
    '';

    dec-volume = super.writers.writeBashBin "dec-volume.sh" ''
    pactl -- set-sink-volume "$(pactl -- get-default-sink)" -10%
    VOL="$(pamixer --get-volume)"
    notify-send -t 1000 -h int:value:$VOL "VOL:"
    '';

    pm = super.writers.writeBashBin "pm.sh" ''
    cd /media/Music
    find ./ -regextype posix-extended -iregex '.*\.(mp3|flac|m4a)' | fzf --height ''${FZF_TMUX_HEIGHT:-40%} |
      sort | uniq | xargs -r -d '\n' mpv --audio-display=no
    '';

    nsxiv = super.symlinkJoin {
      name = "nsxiv";
      paths = [ super.nsxiv ];
      buildInputs = [ super.makeWrapper ];
      postBuild = ''
      wrapProgram $out/bin/nsxiv \
        --set XDG_CONFIG_HOME /etc/nixos/overlays
      '';
    };

    mpv = super.symlinkJoin {
      name = "mpv";
      paths = [ super.mpv ];
      buildInputs = [ super.makeWrapper ];
      postBuild = ''
      wrapProgram $out/bin/mpv \
        --set XDG_CONFIG_HOME /etc/nixos/overlays
      '';
    };

  })
  ];

  networking.hostName = "Synthesis"; # Define your hostname.
  # Pick only one of the below networking options.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  networking.wireless.networks = {
    Ginkgo = {
      psk = (import ./passwords.nix).ginkgo;
    };

    Home = {
      psk = (import ./passwords.nix).home;
    };
  };

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkbOptions in tty.
  };

  services.xserver = {
    enable = true;
    displayManager.sx.enable = true;
    # windowManager.dwm.enable = true;
    libinput.enable = true;

    layout = "us";
    # https://gist.github.com/jatcwang/ae3b7019f219b8cdc6798329108c9aee
    xkbOptions = "ctrl:nocaps,altwin:swap_alt_win";
  };

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.bluetooth.enable = true;

  services.blueman.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = {
  #   "eurosign:e";
  #   "caps:escape" # map caps to escape.
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.vector = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    
    shell = "/run/current-system/sw/bin/zsh";
  };
  users.users.root.shell = "/run/current-system/sw/bin/zsh";

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    extraConfig = ''
      # For the true color supposed to work
      set -g default-terminal "screen-256color"
      # tell Tmux that outside terminal supports true color
      set -ga terminal-overrides ",xterm-256color*:Tc"

      # Status Bar
      set-option -g status-interval 5
      set-option -g automatic-rename on
      set-option -g automatic-rename-format '#{b:pane_current_path}'

      # set clipboard on
      set-option -g set-clipboard external

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection
      bind-key -T copy-mode-vi r send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi C-u send-keys -X scroll-up
      bind-key -T copy-mode-vi C-d send-keys -X scroll-down

      # default statusbar colors
      set-option -g status-style "fg=#bbbbbb,bg=#005577"
      # default window title colors
      set-window-option -g window-status-style "fg=#85939E,bg=default"
      # active window title colors
      set-window-option -g window-status-current-style "fg=#eeeeee,bg=default"
      # pane border
      set-option -g pane-border-style "fg=#222E38"
      set-option -g pane-active-border-style "fg=#586875"
      # message text
      set-option -g message-style "fg=#A6AFB8,bg=#222E38"
      # pane number display
      set-option -g display-panes-active-colour "#7CC844"
      set-option -g display-panes-colour "#E4B51C"
      # clock
      set-window-option -g clock-mode-colour "#7CC844"
      # copy mode highligh
      set-window-option -g mode-style "fg=#85939E,bg=#586875"
      # bell
      set-window-option -g window-status-bell-style "fg=#222E38,bg=#EF5253"
    '';
  };

  programs.git = {
    enable = true;
    config = {
      init = {
        defaultBranch = "master";
      };
      user = {
        name = "versorspace";
        email = "resoaxes@gmail.com";
      };
      safe = {
        directory = [
	  "/etc/nixos"
	];
      };
    };
  };

  # programs.neovim = {
  #   enable = true;
  #   vimAlias = true;
  #   viAlias = true;
  #   defaultEditor = true;

  #   configure = {
  #     customRC = ''
  #     lua << EOF
  #     require'nvim-treesitter.configs'.setup {
  #       highlight = {
  #         -- `false` will disable the whole extension
  #         enable = true,
  #         additional_vim_regex_highlighting = false,
  #         }
  #     }

  #     require('nightfox').init({
  #       transparent = true,
  #     })
  #     EOF
  #     set termguicolors
  #     colorscheme nightfox

  #     function CopyDirPath()
  #       call system('xclip -i -selection clipboard <<< "\"' . expand('%:p:h') . '"\"')
  #       echom trim('CWD: ' . expand('%:p:h') . ' -> (copied to clipboard)')
  #     endfunction

  #     nnoremap <Leader>cd :call CopyDirPath()<CR>
  #     nnoremap H :tabprev<CR>
  #     nnoremap L :tabnext<CR>

  #     " " " Copy to clipboard
  #     vnoremap  <C-c>  "+y
  #     vnoremap  cy  "+y
  #     " nnoremap  <leader>Y  "+yg_
  #     " nnoremap  <leader>y  "+y
  #     " nnoremap  <leader>yy  "+yy
  #     " 
  #     " " " Paste from clipboard
  #     " nnoremap <leader>p "+p
  #     " nnoremap <leader>P "+P
  #     " vnoremap <leader>p "+p
  #     " vnoremap <leader>P "+P

  #     set mouse-=a
  #     set nu

  #     " Mimic Emacs Line Editing in Insert Mode Only
  #     inoremap <C-A> <Home>
  #     inoremap <C-B> <Left>
  #     inoremap <C-E> <End>
  #     inoremap <C-F> <Right>
  #     inoremap <M-B> <C-Left>
  #     inoremap <M-F> <C-Right>
  #     inoremap <C-K> <Esc>lDa
  #     inoremap <C-U> <Esc>d0xi
  #     inoremap <C-Y> <Esc>Pa
  #     inoremap <C-X><C-S> <Esc>:w<CR>a

  #     set ignorecase
  #     set smartcase
  #     '';

  #     packages.myVimPackage = with pkgs.vimPlugins; {
  #       # launch on start
  #       start = [
  #         vim-surround
  #         nightfox-nvim
  #         gruvbox-nvim
  #         (nvim-treesitter.withPlugins
  #           (_: pkgs.tree-sitter.allGrammars)
  #         )
  #       ];
  #     };
  #   };
  # };

  programs.bash = {
    enableCompletion = true;
    # promptInit = ''
    # # Provide a nice prompt if the terminal supports it.
    # if [ "$TERM" != "dumb" ] || [ -n "$INSIDE_EMACS" ]; then
    #   PROMPT_COLOR="1;31m"
    #   ((UID)) && PROMPT_COLOR="1;32m"
    #   if [ -n "$INSIDE_EMACS" ] || [ "$TERM" = "eterm" ] || [ "$TERM" = "eterm-color" ]; then
    #     # Emacs term mode doesn't support xterm title escape sequence (\e]0;)
    #     PS1="\[\033[$PROMPT_COLOR\][\u@\h:\w]\n\\$\[\033[0m\] "
    #     # PS1='$ '
    #   else
    #     PS1='$ '
    #   fi
    #   if test "$TERM" = "xterm"; then
    #     PS1="\[\033]2;\h:\u:\w\007\]$PS1"
    #   fi
    # fi
    # '';
    interactiveShellInit = ''
    shopt -s autocd
    shopt -s globstar
    shopt -s extglob
    # shopt -s failglob
    shopt -s cmdhist
    shopt -s lithist
    shopt -s histappend
    export HISTCONTROL=ignoredups:erasedups
    export HISTTIMEFORMAT='%F %T '
    # for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
    export HISTSIZE=50000000
    export HISTFILESIZE=100000
    '';
  };

  programs.zsh = {
    enable = true;

    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

    interactiveShellInit = ''
      source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
    '';

    setOptions = [
      "HIST_IGNORE_DUPS"
      "SHARE_HISTORY"
      "HIST_FCNTL_LOCK"
      "AUTO_CD"
      "INTERACTIVE_COMMENTS"
      "VI"
      "AUTO_MENU"
      "NOTIFY"
      "COMPLETE_IN_WORD"
      "NO_HUP"
      "AUTO_PUSHD"
      "NO_BEEP"
      "PUSHD_IGNORE_DUPS"
      "UNSET"
    ];

    shellInit = ''
      bindkey '^E' end-of-line
      setopt vi
      bindkey -v '^?' backward-delete-char

      for mod in parameter complist deltochar mathfunc ; do
      	zmodload -i zsh/''${mod} 2>/dev/null
      done && builtin unset -v mod

      # allow one error for every three characters typed in approximate completer
      zstyle ':completion:*:approximate:'    max-errors 'reply=( $((($#PREFIX+$#SUFFIX)/3 )) numeric )'
      
      # don't complete backup files as executables
      zstyle ':completion:*:complete:-command-::commands' ignored-patterns '(aptitude-*|*\~)'
      
      # start menu completion only if it could find no unambiguous initial string
      zstyle ':completion:*:correct:*'       insert-unambiguous true
      zstyle ':completion:*:corrections'     format $'%{\e[0;31m%}%d (errors: %e)%{\e[0m%}'
      zstyle ':completion:*:correct:*'       original true
      
      # activate color-completion
      zstyle ':completion:*:default'         list-colors ''${(s.:.)LS_COLORS}
      
      # format on completion
      zstyle ':completion:*:descriptions'    format $'%{\e[0;31m%}completing %B%d%b%{\e[0m%}'
      
      # automatically complete 'cd -<tab>' and 'cd -<ctrl-d>' with menu
      # zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
      
      # insert all expansions for expand completer
      zstyle ':completion:*:expand:*'        tag-order all-expansions
      zstyle ':completion:*:history-words'   list false
      
      # activate menu
      zstyle ':completion:*:history-words'   menu yes
      
      # ignore duplicate entries
      zstyle ':completion:*:history-words'   remove-all-dups yes
      zstyle ':completion:*:history-words'   stop yes
      
      # match uppercase from lowercase
      zstyle ':completion:*'                 matcher-list 'm:{a-z}={A-Z}'
      
      # separate matches into groups
      zstyle ':completion:*:matches'         group 'yes'
      zstyle ':completion:*'                 group-name '''
      
      if [[ "$NOMENU" -eq 0 ]] ; then
          # if there are more than 5 options allow selecting from a menu
          zstyle ':completion:*'               menu select=5
      else
          # don't use any menus at all
          setopt no_auto_menu
      fi
      
      zstyle ':completion:*:messages'        format '%d'
      zstyle ':completion:*:options'         auto-description '%d'
      
      # describe options in full
      zstyle ':completion:*:options'         description 'yes'
      
      # on processes completion complete all user processes
      zstyle ':completion:*:processes'       command 'ps -au$USER'
      
      # offer indexes before parameters in subscripts
      zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
      
      # provide verbose completion information
      zstyle ':completion:*'                 verbose true
      
      # recent (as of Dec 2007) zsh versions are able to provide descriptions
      # for commands (read: 1st word in the line) that it will list for the user
      # to choose from. The following disables that, because it's not exactly fast.
      zstyle ':completion:*:-command-:*:'    verbose false
      
      # set format for warnings
      zstyle ':completion:*:warnings'        format $'%{\e[0;31m%}No matches for:%{\e[0m%} %d'
      
      # define files to ignore for zcompile
      zstyle ':completion:*:*:zcompile:*'    ignored-patterns '(*~|*.zwc)'
      zstyle ':completion:correct:'          prompt 'correct to: %e'
      
      # Ignore completion functions for commands you don't have:
      zstyle ':completion::(^approximate*):*:functions' ignored-patterns '_*'
      
      # Provide more processes in completion of programs like killall:
      zstyle ':completion:*:processes-names' command 'ps c -u ''${USER} -o command | uniq'
      
      # complete manual by their section
      zstyle ':completion:*:manuals'    separate-sections true
      zstyle ':completion:*:manuals.*'  insert-sections   true
      zstyle ':completion:*:man:*'      menu yes select

      ## use the vi navigation keys (hjkl) besides cursor keys in menu completion
      bindkey -M menuselect 'h' vi-backward-char        # left
      bindkey -M menuselect 'k' vi-up-line-or-history   # up
      bindkey -M menuselect 'l' vi-forward-char         # right
      bindkey -M menuselect 'j' vi-down-line-or-history # bottom

      alias xclipco='xclip -o -selection clipboard'
      alias gg='git log --oneline'
      alias alto='xdotool set_window --class dwmalto "$(xdotool getactivewindow)"'

      # Ctrl-s will no longer disable input
      stty -ixon

      ggrep () {
        grep -vnriI "^$" *  | fzf --delimiter : --preview='bat --style=full --color=always {1} --highlight-line={2} {3..}' --preview-window '~3,+{2}+3/2'
      }

      function preexec () {
      	echo -ne "\033]0;$PWD \$ $history[$(print -P %h)]\a"
      }

      function precmd () {
      	echo -ne "\033]0;$PWD\a"
      }

      export ZVM_CURSOR_STYLE_ENABLED=false
    '';

    enableCompletion = true;
    autosuggestions.enable = true;
    autosuggestions.async = true;
    syntaxHighlighting.enable = true;
    histSize = 100000;
  };


  # programs.zsh = {
  #   enable = true;
  #   # promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  #   interactiveShellInit = ''
  #   source ${pkgs.grml-zsh-config}/etc/zsh/zshrc

  #   alias xclipco='xclip -o -selection clipboard'
  #   alias vim=nvim
  #   setopt vi
  #   export HISTSIZE=100000
  #   bindkey -v '^?' backward-delete-char

  #   function venvns {
  #       if ! [[ -z $VIRTUAL_ENV ]];
  #       then
  #           # REPLY="(""$(basename "''${VIRTUAL_ENV}")"") "
  #           REPLY="(""''${VIRTUAL_ENV##*/}"")"" "
  #       fi
  #   }

  #   function +vi-git-untracked() {
  #   	emulate -L zsh
  #       if [[ -n $(git ls-files --exclude-standard --others 2> /dev/null) ]];
  #       then
  #       	hook_com[unstaged]+="%F{12}"
  #       fi
  #   }

  #   function git_pushable() {
  #   	setopt localoptions noshwordsplit
  #   	if git rev-list --count "origin/$(git rev-parse --abbrev-ref HEAD 2>/dev/null).." > /dev/null 2>&1;
  #       then
  #   		RESULT=$(git rev-list --count "origin/$(git rev-parse --abbrev-ref HEAD 2>/dev/null).." | sed 's/[1-9][0-9]*/ ↯/;s/[0-9]//' | tr -d '\n')
  #       	REPLY="%B%F{11}''${RESULT}%f%b"
  #   	fi
  #   }

  #   function userns() {
  #   	if ((EUID == 0 ));
  #       then
  #       	REPLY="%B%F{1}%n%f%b"
  #       else
  #       	REPLY="%B%F{12}%n%f%b"
  #       fi
  #   }

  #   autoload -Uz vcs_info
  #   zstyle ':vcs_info:*' enable git
  #   zstyle ':vcs_info:*' check-for-changes true
  #   zstyle ':vcs_info:*' stagedstr "%F{3}"
  #   zstyle ':vcs_info:*' unstagedstr "%F{1}"
  #   zstyle ':vcs_info:*' use-simple true
  #   zstyle ':vcs_info:git+set-message:*' hooks git-untracked
  #   zstyle ':vcs_info:git*:*' formats '%F{2}%u%c%m%b%f'
  #   zstyle ':vcs_info:git*:*' actionformats '%u%c%m%b/%a' # default ' (%s)-[%b|%a]%c%u-'

  #   grml_theme_add_token pushable -f git_pushable
  #   grml_theme_add_token userns -f userns
  #   grml_theme_add_token venvns -f venvns '%B%F{7}' '%b%f'
  #   # grml_theme_add_token daytime '%K{240}[%D{%a %b %d} %T]' '%F{white}' '%f%k'
  #   grml_theme_add_token datetime '%D{%a %b %d} %T' '[%F{257}' '%f] '
  #   grml_theme_add_token datens '%D{%a %b %d}' '%F{257}' '%f '
  #   grml_theme_add_token timens '%D{%T}' '%F{257}' '%f '
  #   grml_theme_add_token hostns '%M' '%F{257}' '%f '
  #   # grml_theme_add_token pathns '%/' '%U%F{11}' '%f%u '
  #   grml_theme_add_token pathns '%~' '%F{3}' '%f '
  #   grml_theme_add_token curdir '%1~' '%B%F{4}' '%f%b '
  #   grml_theme_add_token dollar '$' '%F{257}' '%f '

  #   zstyle ':prompt:grml:left:setup' items datens curdir userns at hostns newline timens venvns rc dollar

  #   zstyle ':prompt:grml:right:setup' items vcs pushable

  #   function preexec () {
  #     echo -ne "\033]0;$PWD \$: $history[$(print -P %h)]\a"
  #   }
  #   
  #   function precmd () {
  #     echo -ne "\033]0;$TERM\a"
  #     #vcs_info
  #   }

  #   '';

  #   promptInit = "";
  # };

  # nix.extraOptions = ''
  # experimental-features = nix-command
  # '';

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
  };

  fonts = {
    #fontDir.enable = true;
    fonts = with pkgs; [
      corefonts
      inconsolata-nerdfont
      terminus-nerdfont
      dejavu_fonts
      tamsyn
      tamzen
      freefont_ttf
      google-fonts
      noto-fonts-emoji
      inconsolata
      iosevka
      liberation_ttf
      ubuntu_font_family
      meslo-lgs-nf
      jetbrains-mono
      nerdfonts
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  programs.adb.enable = true;

  environment = {
    systemPackages = with pkgs; [ wget firefox chromium sx nsxiv mpv aria2 fzf
      maim signal-desktop slstatus dunst acpi jq dmenu file picom htop unzip 
      gimp nix-index hsetroot xdotool alsa-utils pulseaudio
      dwm-alto dwm-screenshot libnotify pamixer xorg.xkill xorg.xfontsel killall
      dec-volume inc-volume xclip sshfs bat parallel pm perl zsh nix-prefetch-scripts
      spotify perl tdesktop tesseract
    ];

    variables = {
      FZF_DEFAULT_OPTS="-e --multi --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle,Home:preview-page-up,End:preview-page-down --preview-window=wrap";
    };
  };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}

