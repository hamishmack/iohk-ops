{ mkDerivation, async, base, bytestring, Cabal, containers
, data-fix, directory, fetchgit, filepath, Glob, hnix
, monad-parallel, optparse-applicative, process, SafeSemaphore
, stdenv, temporary, text, yaml
}:
mkDerivation {
  pname = "stack2nix";
  version = "0.1.3.0";
  src = fetchgit {
    url = "https://github.com/input-output-hk/stack2nix.git";
    sha256 = "00ghkhf3qpi50v8f7qz08f3rnhxf8dwx992vfw2bd9daawbkd96i";
    rev = "a46ae2d2e820f6a20b25f6a12cd1b97f202db8d7";
  };
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    async base bytestring Cabal containers data-fix directory filepath
    Glob hnix monad-parallel process SafeSemaphore temporary text yaml
  ];
  executableHaskellDepends = [ base Cabal optparse-applicative ];
  doCheck = false;
  description = "Convert stack.yaml files into Nix build instructions.";
  license = stdenv.lib.licenses.mit;
}
