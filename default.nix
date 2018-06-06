{ pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs-channels/archive/696c6bed4e8e2d9fd9b956dea7e5d49531e9d13f.tar.gz";
    sha256 = "1v3yrpj542niyxp0h3kffsdjwlrkvj0mg4ljb85d142gyn3sdzd4";
  }) {}
}:

with pkgs;

pkgs.dockerTools.buildImage {
  name = "ziptopdf";
  tag = "latest";
  keepContentsDirlinks = true;
  contents = [
    (buildEnv {
      name = "ziptopdf";
      paths = [
        (stdenv.mkDerivation {
          name = "ziptopdf";
          src = ./server.py;
          builder = pkgs.writeTextFile {
            name = "builder.pl";
            text = ''
              source $stdenv/setup
              mkdir -p $out/bin
              mkdir -p $out/usr/bin
              cp $src $out/bin/server.py
              chmod u+x $out/bin/server.py
              ln -s ${busybox}/bin/env $out/usr/bin/env
            '';
          };
        })
        (texlive.combine {
          inherit (texlive)
            scheme-basic
            epstopdf
            etoolbox
            fancyvrb
            float
            framed
            fvextra
            ifplatform
            latex
            lineno
            minted
            upquote
            xcolor
            xstring;
        })
        busybox
        ghostscript
        (python3.buildEnv.override {
          extraLibs = with python3Packages; [ pygments aiohttp ];
        })
      ];
    })
  ];
  runAsRoot = ''
     #!${stdenv.shell}
     mkdir -p /tmp
  '';
  config = {
    Cmd = [ "/bin/server.py" ];
    WorkindDir = "/tmp";
    Env = [
      "PATH=/bin"
      "TMPDIR=/tmp"
    ];
    ExposedPort = {
      "8080/tcp" = {};
    };
  };
}
