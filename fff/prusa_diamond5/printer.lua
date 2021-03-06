-- Diamond with Diamond 5 filaments

version = 2

function comment(text)
  output('; ' .. text)
end

extruder_e = 0
extruder_e_reset = 0
extruder_e_adjusted = 0

current_A = 0.20
current_B = 0.20
current_C = 0.20
current_D = 0.20
current_H = 0.20

function header()
  auto_level_string = 'G29 ; auto bed levelling\nG0 F6200 X0 Y0 ; back to the origin to begin the purge '
  
  h = file('header.gcode')
  h = h:gsub( '<TOOLTEMP>', extruder_temp_degree_c[extruders[0]] )
  h = h:gsub( '<HBPTEMP>', bed_temp_degree_c )

  if auto_bed_leveling == true then
    h = h:gsub( '<BEDLVL>', auto_level_string )
  else
    h = h:gsub( '<BEDLVL>', "G0 F6200 X0 Y0" )
  end

  output(h)
end

function footer()
  output(file('footer.gcode'))
end

function layer_start(zheight)
  comment('<layer>')
  output('G92 E0')
  extruder_e_reset = extruder_e
  output('G1 Z' .. f(zheight))
end

function layer_stop()
  comment('</layer>')
end

function retract(extruder,e)
  len   = filament_priming_mm[extruder] * nb_nozzle_in
  speed = (priming_mm_per_sec * nb_nozzle_in) * 60;
  letter = ' E'

  if filament_diameter_management == true then
    extruder_e_adjusted = extruder_e_adjusted - len
    output('G1 F' .. speed .. letter .. ff(extruder_e_adjusted-extruder_e_reset) .. ' A0.20 B0.20 C0.20 D0.20 H0.20 ')
  else
    output('G1 F' .. speed .. letter .. ff(e - len - extruder_e_reset) .. ' A0.20 B0.20 C0.20 D0.20 H0.20')
  end

  extruder_e = e - len
  return e - len
end

function prime(extruder,e)
  len   = filament_priming_mm[extruder] * nb_nozzle_in
  speed = (priming_mm_per_sec * nb_nozzle_in) * 60;
  letter = ' E'

  if filament_diameter_management == true then
    extruder_e_adjusted = extruder_e_adjusted + len
    output('G1 F' .. speed .. letter .. ff(extruder_e_adjusted-extruder_e_reset) .. ' A0.20 B0.20 C0.20 D0.20 H0.20 ')
  else
    output('G1 F' .. speed .. letter .. ff(e + len - extruder_e_reset) .. ' A0.20 B0.20 C0.20 D0.20 H0.20')
  end
  
  extruder_e = e + len
  return e + len
end

current_extruder = 0
current_frate = 0

function select_extruder(extruder)
end

function swap_extruder(from,to,x,y,z)
end

function move_xyz(x,y,z)
  output('G1 X' .. f(x) .. ' Y' .. f(y) .. ' Z' .. f(z+z_offset))
end

function move_xyze(x,y,z,e)
  letter = ' E'
  if path_is_raft then
    current_A = 0.2
    current_B = 0.2
    current_C = 0.2
    current_D = 0.2
    current_H = 0.2
  end
  
  delta_e    = e - extruder_e
  extruder_e = e
  
  -- adjust based on filament diameters
  if filament_diameter_management == true then
    r_a = current_A * (filament_diameter_mm_0 * filament_diameter_mm_0)
          / (filament_diameter_A * filament_diameter_A)
    r_b = current_B * (filament_diameter_mm_0 * filament_diameter_mm_0)
          / (filament_diameter_B * filament_diameter_B)
    r_c = current_C * (filament_diameter_mm_0 * filament_diameter_mm_0)
          / (filament_diameter_C * filament_diameter_C)
    r_d = current_D * (filament_diameter_mm_0 * filament_diameter_mm_0)
          / (filament_diameter_D * filament_diameter_D)
    r_h = current_H * (filament_diameter_mm_0 * filament_diameter_mm_0)
          / (filament_diameter_H * filament_diameter_H)
    sum = (r_a + r_b + r_c + r_d + r_h)
    r_a = r_a / sum
    r_b = r_b / sum
    r_c = r_c / sum
    r_d = r_d / sum
    r_h = r_h / sum
    delta_e_adjusted = delta_e * sum
    extruder_e_adjusted = extruder_e_adjusted + delta_e_adjusted
    output('G1 X' .. f(x) .. ' Y' .. f(y) .. ' Z' .. f(z+z_offset) .. ' F' .. current_frate .. ' ' .. letter .. ff(extruder_e_adjusted-extruder_e_reset) .. ' A' .. f(r_a) .. ' B' .. f(r_b) .. ' C' .. f(r_c) .. ' D' .. f(r_d) .. ' H' .. f(r_h))
  -------------------------------------
  else 
    output('G1 X' .. f(x) .. ' Y' .. f(y) .. ' Z' .. f(z+z_offset) .. ' F' .. current_frate .. ' ' .. letter .. ff(e - extruder_e_reset) .. ' A' .. f(current_A) .. ' B' .. f(current_B) .. ' C' .. f(current_C) .. ' D' .. f(current_D) .. ' H' .. f(current_H))
  end
end

function move_e(e)
  delta_e             = e - extruder_e
  extruder_e          = e
  extruder_e_adjusted = extruder_e_adjusted + delta_e
  letter = ' E'
  output('G1 ' .. letter .. ff(e-extruder_e_reset))
end

function set_feedrate(feedrate)
  feedrate = math.floor(feedrate)
  output('G1 F' .. feedrate)
  current_frate = feedrate
end

function extruder_start()
end

function extruder_stop()
end

function progress(percent)
end

function set_extruder_temperature(extruder,temperature)
  output('M104 S' .. temperature .. ' T' .. extruder)
end

function set_mixing_ratios(ratios)
  sum = ratios[0] + ratios[1] + ratios[2] + ratios[3] + ratios[4]
  if sum == 0 then
    ratios[0] = 0.2
    ratios[1] = 0.2
    ratios[2] = 0.2
    ratios[3] = 0.2
    ratios[4] = 0.2
  end
  current_A = ratios[0]
  current_B = ratios[1]
  current_C = ratios[2]
  current_D = ratios[3]
  current_H = ratios[4]
end

current_fan_speed = -1
function set_fan_speed(speed)
  if speed ~= current_fan_speed then
    output('M106 S'.. math.floor(255 * speed/100))
    current_fan_speed = speed
  end
end
