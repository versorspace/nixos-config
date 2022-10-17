# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
    st = super.st.override {
      conf = builtins.readFile ./overlays/st/config.h;
      patches = [
        ./overlays/st/st-externalpipe-0.8.4.diff
        ./overlays/st/st-newterm-extpipecompat.diff
	./overlays/st/st-scrollback-0.8.5.diff
	./overlays/st/st-scrollback-mouse-20220127-2c5edf2.diff
	./overlays/st/st-scrollback-mouse-altscreen-20220127-2c5edf2.diff
        ./overlays/st/st-alpha-20220206-0.8.5.diff
        ./overlays/st/st-anysize-20220718-baa9357.diff
        ./overlays/st/st-bold-is-not-bright-20190127-3be4cf1.diff
        ./overlays/st/st-ubuntu-0.8.5-alpha.diff
	./overlays/st/st-boxdraw_v2.1-0.8.5.diff
	./overlays/st/st-glyph-wide-support-boxdraw.diff
	./overlays/st/st-font2-0.8.5.diff
	./overlays/st/st-externalpipe-eternal-0.8.3.diff
	./overlays/st/7672445bab01cb4e861651dc540566ac22e25812.diff
	./overlays/st/st-autocomplete-0.8.5.diff
	# ./overlays/st/st-0.8.5-autocomplete-20220327-230120.diff
	# ./overlays/st/st-scrollback-reflow-0.8.5v2.diff
        # ./overlays/st/st-fontpatch-0.8.5.diff
        # ./overlays/st/st-focus-0.8.5-patch_alpha.diff
      ];
    };

    dwm = super.dwm.override {
      patches = [
        ./overlays/dwm/dwm-cool-autostart-6.3.diff
        ./overlays/dwm/dwm-moveresize-6.2.diff
        ./overlays/dwm/dwm-fullgaps-6.3.diff
      ];
      conf = builtins.readFile ./overlays/dwm/config.h;
    };

    tabbed = super.tabbed.override {
      customConfig = builtins.readFile ./overlays/tabbed/config.h;
      patches = [ ./overlays/tabbed/alpha.diff ];
    };

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
      st -c dwmalto -e tmux
    fi
    '';

    dwm-screenshot = super.writers.writeBashBin "dwm-screenshot.sh" ''
    maim -s | tee ~/Pictures/$(date +%s).png | xclip -selection clipboard -t image/png
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
    windowManager.dwm.enable = true;
    libinput.enable = true;

    layout = "us";
    # https://gist.github.com/jatcwang/ae3b7019f219b8cdc6798329108c9aee
    xkbOptions = "ctrl:nocaps";
  };

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

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

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;

    configure = {
      customRC = ''
      set termguicolors
      colorscheme nightfox
      "hi Normal guibg=None
      "hi NonText guibg=None

      lua << EOF
      require'nvim-treesitter.configs'.setup {
        highlight = {
          -- `false` will disable the whole extension
          enable = true,
          additional_vim_regex_highlighting = false,
          }
      }
      EOF

      function CopyDirPath()
        call system('xclip -i -selection clipboard <<< "\"' . expand('%:p:h') . '"\"')
        echom trim('CWD: ' . expand('%:p:h') . ' -> (copied to clipboard)')
      endfunction

      nnoremap <Leader>cd :call CopyDirPath()<CR>
      nnoremap H :tabprev<CR>
      nnoremap L :tabnext<CR>

      " " " Copy to clipboard
      vnoremap  <C-c>  "+y
      vnoremap  cy  "+y
      " nnoremap  <leader>Y  "+yg_
      " nnoremap  <leader>y  "+y
      " nnoremap  <leader>yy  "+yy
      " 
      " " " Paste from clipboard
      " nnoremap <leader>p "+p
      " nnoremap <leader>P "+P
      " vnoremap <leader>p "+p
      " vnoremap <leader>P "+P

      set mouse-=a
      '';

      packages.myVimPackage = with pkgs.vimPlugins; {
        # launch on start
        start = [
          vim-surround
          nightfox-nvim
          (nvim-treesitter.withPlugins
	    (_: pkgs.tree-sitter.allGrammars)
	  )
        ];
      };
    };
  };


  programs.zsh = {
    enable = true;
    # promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    interactiveShellInit = ''
    source ${pkgs.grml-zsh-config}/etc/zsh/zshrc

    alias xclipco='xclip -o -selection clipboard'
    alias vim=nvim
    setopt vi
    export HISTSIZE=100000
    bindkey -v '^?' backward-delete-char

    function venvns {
        if ! [[ -z $VIRTUAL_ENV ]];
        then
            # REPLY="(""$(basename "''${VIRTUAL_ENV}")"") "
            REPLY="(""''${VIRTUAL_ENV##*/}"")"" "
        fi
    }

    function +vi-git-untracked() {
    	emulate -L zsh
        if [[ -n $(git ls-files --exclude-standard --others 2> /dev/null) ]];
        then
        	hook_com[unstaged]+="%F{12}"
        fi
    }

    function git_pushable() {
    	setopt localoptions noshwordsplit
    	if git rev-list --count "origin/$(git rev-parse --abbrev-ref HEAD 2>/dev/null).." > /dev/null 2>&1;
        then
    		RESULT=$(git rev-list --count "origin/$(git rev-parse --abbrev-ref HEAD 2>/dev/null).." | sed 's/[1-9][0-9]*/ ↯/;s/[0-9]//' | tr -d '\n')
        	REPLY="%B%F{11}''${RESULT}%f%b"
    	fi
    }

    function userns() {
    	if ((EUID == 0 ));
        then
        	REPLY="%B%F{1}%n%f%b"
        else
        	REPLY="%B%F{12}%n%f%b"
        fi
    }

    autoload -Uz vcs_info
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr "%F{3}"
    zstyle ':vcs_info:*' unstagedstr "%F{1}"
    zstyle ':vcs_info:*' use-simple true
    zstyle ':vcs_info:git+set-message:*' hooks git-untracked
    zstyle ':vcs_info:git*:*' formats '%F{2}%u%c%m%b%f'
    zstyle ':vcs_info:git*:*' actionformats '%u%c%m%b/%a' # default ' (%s)-[%b|%a]%c%u-'

    grml_theme_add_token pushable -f git_pushable
    grml_theme_add_token userns -f userns
    grml_theme_add_token venvns -f venvns '%B%F{7}' '%b%f'
    # grml_theme_add_token daytime '%K{240}[%D{%a %b %d} %T]' '%F{white}' '%f%k'
    grml_theme_add_token datetime '%D{%a %b %d} %T' '[%F{257}' '%f] '
    grml_theme_add_token datens '%D{%a %b %d}' '%F{257}' '%f '
    grml_theme_add_token timens '%D{%T}' '%F{257}' '%f '
    grml_theme_add_token hostns '%M' '%F{257}' '%f '
    # grml_theme_add_token pathns '%/' '%U%F{11}' '%f%u '
    grml_theme_add_token pathns '%~' '%F{3}' '%f '
    grml_theme_add_token curdir '%1~' '%B%F{4}' '%f%b '
    grml_theme_add_token dollar '$' '%F{257}' '%f '

    zstyle ':prompt:grml:left:setup' items datens curdir userns at hostns newline timens venvns rc dollar

    zstyle ':prompt:grml:right:setup' items vcs pushable

    function preexec () {
      echo -ne "\033]0;$PWD \$: $history[$(print -P %h)]\a"
    }
    
    function precmd () {
      echo -ne "\033]0;$TERM\a"
      #vcs_info
    }

    '';

    promptInit = "";
  };

  nix.extraOptions = ''
  experimental-features = nix-command
  '';

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
      dejavu_fonts
      freefont_ttf
      google-fonts
      inconsolata
      liberation_ttf
      ubuntu_font_family
      meslo-lgs-nf
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  environment = {
    systemPackages = with pkgs; [ wget firefox chromium sx nsxiv mpv aria2 fzf
      st maim tdesktop slstatus dunst acpi jq dmenu file picom htop unzip 
      gimp nix-index hsetroot xdotool alsa-utils pulseaudio
      dwm-alto dwm-screenshot libnotify pamixer xorg.xkill killall
      dec-volume inc-volume xclip sshfs bat parallel pm perl
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

