{ pkgs ? import <nixpkgs> {} }:
with pkgs; mkShell (let
  buildInputs = [
    # Misc stuff for *-sys crates    
    rustup
    binutils
    cmake
    clang
    libclang.lib
    lld
    pkg-config

		# Other embassyOS dependencies
    openssl
		yq-go
		deno
		#embassy-sdk
  ];
  in {
  name = "embassyos-package"; 
  buildInputs = buildInputs;
  shellHook =
  ''
    export LD_LIBRARY_PATH="${lib.makeLibraryPath buildInputs}"
    export OPENSSL_DIR="${pkgs.openssl}"
    export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
    export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
		embassy-sdk init
  '';
})
