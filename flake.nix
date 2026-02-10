{
  description = "FPGA dev shell";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  
  outputs = {self, nixpkgs}:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
  in
  {
    devShells.${system}.default =
      pkgs.mkShell
        {
          buildInputs = [
            pkgs.ghdl
            pkgs.gtkwave
            pkgs.fusesoc
            pkgs.ghdl
            pkgs.gtkwave
          ];
          
          shellHook = ''
            mkdir tb;
            mkdir rtl;
            fusesoc library add .;
          '';
        };
  };
}