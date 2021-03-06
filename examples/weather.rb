class WeatherPlugin
  include Purugin::Plugin
  description 'Weather', 0.1

  def on_enable
    include_plugin_module 'Commands', 'Command'

    config = load_configuration
    like_weather = config.get_boolean('weather.storms', true)

    command('/weather', '[stop|start] to toggle weather') do |e, cmd, *args|
      p = e.player

      if args.empty?
        p.send_message "weather: #{p.world.has_storm ? "storms": "clear skies"}"
      elsif args[0] == 'stop'
        p.world.storm = false
        p.world.thundering = false
        p.send_message "weather: storm stopped"
      elsif args[0] == 'start'
        p.world.storm = true
        p.send_message "weather: storm started"
      elsif args[0] == 'disable'
        like_weather = false
        config.set! 'weather.storms', false
        p.send_message "weather: disabled"
      elsif args[0] == 'enable'
        like_weather = true
        config.set! 'weather.storms', true
        p.send_message "weather: enabled"
      end
    end

    event(:weather_change, :highest) do |e| 
      e.cancelled = true if !like_weather && e.to_weather_state
    end
    event(:thunder_change, :highest) do |e|
      e.cancelled = true if !like_weather && e.to_thunder_state 
    end
    event(:lightning_strike, :highest) { |e| e.cancelled = true }
    event(:world_load, :monitor) do |e|
      unless like_weather
        server.worlds.each do |world|
          world.storm = false if world.hasStorm
          world.thundering = false if world.isThundering
        end
      end
    end
  end
end
