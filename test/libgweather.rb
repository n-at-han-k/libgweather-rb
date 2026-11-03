# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "libgweather"

describe GWeather do
  it "defines the namespace from the typelib" do
    # Not an arbitrary number: it is the point of the loader. A hand-written
    # binding exposes what someone got round to wrapping; this exposes what
    # GWeather-4.0.typelib has, which is a handful of classes plus the unit
    # and condition enums. A drop to single digits means the loader half-ran.
    expect(GWeather.constants.size).to be > 10
  end

  it "defines the classes a caller actually reaches for" do
    expect(GWeather.const_defined?(:Info)).to be == true
    expect(GWeather.const_defined?(:Location)).to be == true
  end

  it "defines the enumerations that name the units and conditions" do
    expect(GWeather::TemperatureUnit::CENTIGRADE).not.to be_nil
    expect(GWeather::SpeedUnit::KPH).not.to be_nil
    expect(GWeather::Sky::CLEAR).not.to be_nil
  end

  it "maps instance methods onto a class, not just constants" do
    # A loader that registered the types but defined no methods would still
    # satisfy every assertion above, so this is the one that catches a
    # half-loaded namespace.
    expect((GWeather::Info.instance_methods - Object.instance_methods).size).to be > 20
    expect((GWeather::Location.instance_methods - Object.instance_methods).size).to be > 20
  end

  it "produces GObject classes rather than bare Ruby ones" do
    expect(GWeather::Info.ancestors).to be(:include?, GLib::Object)
    expect(GWeather::Location.ancestors).to be(:include?, GLib::Object)
  end

  it "calls a module-level function through the typelib" do
    expect(GWeather.sky_to_string(GWeather::Sky::CLEAR)).to be_a(String)
  end

  describe GWeather::Location do
    # The world database is a real C call returning a real object graph, and
    # it needs no main loop and no display.
    let(:world) { GWeather::Location.world }

    it "loads the world database" do
      expect(world).to be_a(GWeather::Location)
      expect(world.level).to be == GWeather::LocationLevel::WORLD
    end

    it "walks the database to a named place" do
      country = world.find_by_country_code("GB")

      expect(country).to be_a(GWeather::Location)
      expect(country.name).to be == "United Kingdom"
    end
  end

  describe GWeather::Info do
    # Constructing this is the assertion that the GSettings schema
    # org.gnome.GWeather4 is present: without it GSettings calls g_error and
    # the process dies outright rather than raising. See flake.nix.
    it "constructs" do
      expect(GWeather::Info.new).to be_a(GWeather::Info)
    end

    it "reads back a GObject property" do
      info = GWeather::Info.new
      info.application_id = "org.example.LibgweatherTest"

      expect(info.application_id).to be == "org.example.LibgweatherTest"
    end
  end
end
