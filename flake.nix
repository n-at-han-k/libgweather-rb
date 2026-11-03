{
  description = "libgweather — Ruby bindings";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    mine.url = "github:n-at-han-k/flake.nix";
    mine.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, mine, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = mine.lib.${system};

        gemspecFiles = pkgs.runCommand "libgweather-gemspec" { } ''
          mkdir -p $out/lib/libgweather
          cp ${./libgweather.gemspec}         $out/libgweather.gemspec
          cp ${./lib/libgweather/version.rb}  $out/lib/libgweather/version.rb
        '';

        gems = pkgs.bundlerEnv {
          name = "libgweather-gems";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = import ./gemset.nix;
          extraConfigPaths = [ "${gemspecFiles}/." ];
        };

        # The namespaces the loader needs at require time: GWeather itself, and
        # whatever GWeather-4.0.typelib declares as a dependency, which the loader
        # resolves transitively. Nearly every GNOME typelib needs Gio-2.0.
        #
        # `makeSearchPath` would take each package's *first* output, and glib's
        # first output is `bin`, which carries no typelibs -- hence the explicit
        # `.out`. polkit has the same shape, and that trap cost real time twice.
        typelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0"
          (map (drv: drv.out or drv) [ pkgs.libgweather pkgs.glib ]);

        # libgweather reads its own GSettings schema, org.gnome.GWeather4, as
        # soon as you construct a GWeather::Info -- that is where the default
        # unit preferences and the enabled provider list come from. A missing
        # schema is not a raised exception: GSettings calls g_error and the
        # process dies with
        #   GLib-GIO-ERROR **: No GSettings schemas are installed on the system
        # so the typelib alone is not enough to use this library.
        #
        # The schema is not under share/glib-2.0/schemas in nixpkgs; it is in
        # the per-package directory that `glib.getSchemaPath` computes.
        schemaPath = pkgs.glib.getSchemaPath pkgs.libgweather;
      in
      {
        devShells.default = lib.mkRubyShell {
          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby

            # libgweather itself, for its typelib and its GSettings schema.
            # Taking it from the same nixpkgs as the gobject-introspection gem
            # is not a tidiness point: a typelib built against a different glib
            # registers GIO a second time in the process and dies with
            #   cannot register existing type 'GTlsCertificate'
            libgweather

            skywalking-eyes
          ];

          shellHook = /* bash */ ''
            export GI_TYPELIB_PATH="${typelibPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"

            # See the note on schemaPath above: without this, constructing a
            # GWeather::Info aborts the process rather than raising.
            export GSETTINGS_SCHEMA_DIR="${schemaPath}''${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"

            export BUNDLE_GEMFILE="$PWD/Gemfile"
            export BUNDLE_FROZEN=false

            export LANG="''${LANG:-C.UTF-8}"
            export LC_ALL="''${LC_ALL:-$LANG}"

            export RUBYLIB="$PWD/lib''${RUBYLIB:+:$RUBYLIB}"
          '';
        };
      }
    );
}
