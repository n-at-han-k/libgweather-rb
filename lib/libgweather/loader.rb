# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module GWeather
  # Defines everything in the GWeather namespace from `GWeather-4.0.typelib`.
  #
  # Modelled on ruby-gnome's own loaders -- see
  # gtksourceview5/lib/gtksourceview5/loader.rb for one that has to call the
  # library's init function first, and libsecret/lib/libsecret/loader.rb for
  # one that does not.
  #
  # The version string is the typelib's rather than the library's release
  # number, and the two often differ: this one is "4.0", from
  # `GWeather-4.0.typelib`.
  class Loader < GObjectIntrospection::Loader
    def load
      self.version = "4.0"
      super("GWeather")
    end

    private

    # There is no pre_load hook here, and that was checked rather than
    # assumed: `GWeather-4.0.typelib` declares no `init` function, so unlike
    # GtkSource -- whose loader must call `gtk_source_init` before anything
    # works -- there is nothing to call before the namespace is usable.
    #
    # What libgweather does need is its GSettings schema, org.gnome.GWeather4,
    # which GWeather::Info reads on construction. That is an environment
    # concern, not something a loader can fix: see flake.nix and the README.

    def post_load(repository, namespace)
      require_libraries
    end

    def require_libraries
      # Nothing yet. Hand-written Ruby that improves on what the typelib gives
      # -- an each that yields, a to_s, a keyword-argument constructor -- goes
      # in files required from here, which is the convention ruby-gnome uses
      # for exactly that purpose.
    end
  end
end
