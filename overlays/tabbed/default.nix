{ lib, stdenv, fetchgit, xorgproto, libX11, libXft, customConfig ? null, patches ? [ ] }:

stdenv.mkDerivation {
  pname = "tabbed";
  version = "unstable-2018-03-10";

  src = fetchgit {
    url = "https://git.suckless.org/tabbed";
    rev = "55892ebb0a0417e05ce367a5fadb485de82db90b";
    # sha256 = "0frj2yjaf0mfjwgyfappksfir52mx2xxd3cdg5533m5d88vbmxss";
  };

  inherit patches;

  postPatch = lib.optionalString (customConfig != null) ''
    cp ${builtins.toFile "config.h" customConfig} ./config.h
  '';

  buildInputs = [ xorgproto libX11 libXft ];

  makeFlags = [ "CC:=$(CC)" ];

  installFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    homepage = "https://tools.suckless.org/tabbed";
    description = "Simple generic tabbed fronted to xembed aware applications";
    license = licenses.mit;
    maintainers = with maintainers; [ vrthra ];
    platforms = platforms.linux;
  };
}
