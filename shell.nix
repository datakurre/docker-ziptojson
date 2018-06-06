{ pkgs ? import <nixpkgs> {}
}:

with pkgs;

stdenv.mkDerivation rec {
  name = "env";
  src = ./.;
  env = buildEnv { name = name; paths = buildInputs; };
  builder = builtins.toFile "builder.pl" ''
    source $stdenv/setup; ln -s $env $out
  '';
  buildInputs = [
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
    ghostscript
    python3Packages.pygments
    python3Packages.aiohttp
    busybox
  ];
}

