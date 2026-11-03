# libgweather

Ruby bindings for libgweather, locations and weather for GNOME.

```ruby
require "libgweather"

world = GWeather::Location.world
london = world.find_by_country_code("GB").find_nearest_city(51.5072, -0.1276)

info = GWeather::Info.new
info.location = london
# libgweather requires both of these before it will fetch: the weather
# services it talks to want to know who is asking.
info.application_id = "org.example.Weather"
info.contact_info = "mailto:you@example.com"

info.signal_connect("updated") { puts info.temp }
info.update
```

## How this works, and what it costs to install

The library ships a GObject Introspection typelib — `GWeather-4.0.typelib` — describing
every class, method, property and signal it has. `GWeather::Loader`, about twenty
lines, hands that to ruby-gnome's `GObjectIntrospection::Loader`, which defines
the Ruby classes from it at `require` time.

So this gem is pure Ruby: no extension of its own, no Cargo workspace, no
per-platform binary. You get the whole library rather than the subset somebody
got round to wrapping by hand, and it does not drift when the library gains API.

Be precise about install, though: `gem install libgweather` still compiles C, because
`gobject-introspection` and `glib2` are themselves native extensions built
against glib, so a compiler and glib's development headers are needed. What
this gem adds on top is nothing — those two are what every ruby-gnome
application already has, since `gtk4` depends on them.

## The one thing you must install

The typelib is a C-library artefact, so it belongs to your distribution and
this gem cannot install it:

| | |
|---|---|
| Debian / Ubuntu | `gir1.2-gweather-4.0` |
| Fedora | `libgweather` |
| Arch | `libgweather` |
| nix | `pkgs.libgweather` |

If it is not in the default search path, point `GI_TYPELIB_PATH` at the
directory holding `GWeather-4.0.typelib`. The dev shell in `flake.nix` does this.

**The typelib is not quite the whole story.** libgweather also installs a
GSettings schema, `org.gnome.GWeather4`, which `GWeather::Info` reads on
construction — that is where the default unit preferences and the enabled
provider list come from. A missing schema is not an exception you can rescue:
GSettings calls `g_error` and takes the process with it —

```
GLib-GIO-ERROR **: No GSettings schemas are installed on the system
```

On a distribution the package above installs the schema into the system
directory and compiles it, so there is nothing to do. Under nix the schema is
in a per-package directory, so `GSETTINGS_SCHEMA_DIR` has to point at it; the
dev shell does that with `glib.getSchemaPath`.

**One trap worth knowing.** The typelib must come from the same glib build as
the `gobject-introspection` gem. Mixing two registers GIO twice in one process
and fails with `cannot register existing type 'GTlsCertificate'`. Under nix,
take both from one nixpkgs — and note that glib's typelibs live in its `out`
output, not the default one.

## Development

```sh
nix develop
bin/test
```

## Licence

Apache-2.0. The library itself keeps its own licence; this gem links nothing
and copies no code from it — it reads a description of it at runtime.
