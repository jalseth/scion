{
  description = "Scion CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    go-overlay.url = "github:purpleclay/go-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, go-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ go-overlay.overlays.default ];
        };

        # Use the Go version from go.mod
        go = pkgs.go-bin.fromGoMod ./go.mod;

        # Override the Go package in buildGoModule
        buildGoModule = pkgs.buildGoModule.override { inherit go; };
      in
      {
        packages.scion = buildGoModule {
          pname = "scion";
          version = "0.1.0";
          src = ./.;

          # Update the vendorHash when it changes
          vendorHash = "sha256-x+KvQDBl+IeR3dN02j9sN5GW+MUBpkkp+B2Zm6+PQas=";

          subPackages = [ "cmd/scion" ];

          ldflags = [
            "-s" "-w"
            "-X github.com/GoogleCloudPlatform/scion/pkg/version.Version=v0.1.0"
            "-X github.com/GoogleCloudPlatform/scion/pkg/version.Commit=${self.rev or self.dirtyRev or "unknown"}"
            "-X github.com/GoogleCloudPlatform/scion/pkg/version.BuildTime=unknown"
          ];

          # Necessary for buildGoModule when using newer Go versions
          proxyVendor = true;
        };

        packages.default = self.packages.${system}.scion;

        devShells.default = pkgs.mkShell {
          buildInputs = [ go ];
        };
      }
    );
}
