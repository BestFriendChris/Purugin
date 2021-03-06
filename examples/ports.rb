# Allow placed signs to behave as a teleporter when right clicked on.  The format
# for the sign is line one containing 'Teleporter' and line two containing either:
# a) x, y, z (base 36 offset by +32000) b) {locs_plus_waypoint_name}. In the case of b it 
# will substitute that name with the loc it represents when the sign is placed. You can write
# anything on lines 3 or lower and it will not affect how the sign works as a teleporter.
class PortsPlugin
  include Purugin::Plugin
  description 'Ports', 0.2
  
  def teleporter_loc(state)
    return nil if state.lines.length < 2 || state.get_line(0) != "Teleporter"
    state.get_line(1)
  end
  
  VALUE = '[0-9a-z]+'
  LOC = Regexp.new "(#{VALUE}),(#{VALUE}),(#{VALUE})"
  
  def encode(value)
    (value.to_i + 32000).to_s(36)
  end
  
  def decode(value)
    value.to_i(36) - 32000
  end

  def on_enable
    event(:player_interact) do |e|
      if e.right_click_block? && e.clicked_block.is?(:sign_post, :wall_sign)
        loc = teleporter_loc e.clicked_block.state
        return unless loc 
        
        if loc =~ LOC
          x, y, z = $1, $2, $3
          destination = org.bukkit.Location.new e.player.world, decode(x), decode(y), decode(z)
          server.scheduler.schedule_sync_delayed_task(plugin) { e.player.teleport destination }
        end
      end
    end

    # When signs are placed it will look for {my_waypoint} on the loc line.  If it finds
    # this it will ask LocsPlus plugin if such a waypoint exists.  If so it substitures the 
    # the loc in for the name.    
    event(:sign_change) do |e|
      loc = teleporter_loc e
      return unless loc
      if loc =~ /\{([^}]+)\}/
        waypoint = $1
      
        locs_plus = plugin_manager['LocsPlus']
        return unless locs_plus

        waypoint, loc = *locs_plus.locations(e.player).find { |name, *| name == waypoint }
      end
      
      e.set_line 1, loc[0..2].map {|l| encode(l) }.join(",") if loc
    end
  end
end
