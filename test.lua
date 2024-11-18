-- Launchpad test script
-- for two mini mk3s

local Launchpad = include('launchpad/lib/launchpad')
local getMiniMK3Config = include('launchpad/config/launchpad-mini-mk3')

launchpad1 = nil
launchpad2 = nil

function test()
  local speed = 0.02

  -- flash the logo
  launchpad1:control_pad_on("LOGO", 33, 3)
  launchpad2:control_pad_on("LOGO", 33, 3)
  clock.sleep(1)
  launchpad1:control_pad_off("LOGO")
  launchpad2:control_pad_off("LOGO")

  -- light rotated, grid only
  for y = 1, 8, 1 do
    for x = 1, 16, 1 do
      local lp = x < 9 and launchpad1 or launchpad2
      local mapped_x = x < 9 and x or x - 8
      lp:grid_pad_on(mapped_x, y)
      clock.sleep(speed)
      lp:grid_pad_off(mapped_x, y)
    end
  end

  -- light unrotated, full
  for y = 1, 9, 1 do
    for x = 1, 18, 1 do
      local lp = x < 10 and launchpad1 or launchpad2
      local mapped_x = x < 10 and x or x - 9
      lp:coord_pad_on(mapped_x, y)
      clock.sleep(speed)
      lp:coord_pad_off(mapped_x, y)
    end
  end
end

function handle_event(event, lp_index)
  if not event then return end

  local main_lp = lp_index == 1 and launchpad1 or launchpad2
  local mirr_lp = lp_index == 2 and launchpad1 or launchpad2

  -- grid presses are mirrored with rotation
  -- control presses are mirrored with matching control
  if event.type == "grid_pressed" then
    main_lp:grid_pad_on(event.x, event.y)
    mirr_lp:grid_pad_on(event.x, event.y, 37)
  elseif event.type == "grid_released" then
    main_lp:grid_pad_off(event.x, event.y)
    mirr_lp:grid_pad_off(event.x, event.y)
  elseif event.type == "control_pressed" then
    main_lp:note_pad_on(event.note)
    mirr_lp:note_pad_on(event.note, 37)
  elseif event.type == "control_released" then
    main_lp:note_pad_off(event.note)
    mirr_lp:note_pad_off(event.note, 37)
  end
end

-- called when script loads
function init()
  -- 3 & 4 are just where they are on my device,
  -- they might be different for you
  launchpad1 = Launchpad:create(3, getMiniMK3Config())
  launchpad2 = Launchpad:create(4, getMiniMK3Config())
  launchpad1:all_pads_off()
  launchpad2:all_pads_off()

  -- put them side by side for an 8x16 grid
  launchpad1:set_grid_rotation(3)
  launchpad2:set_grid_rotation(0)

  -- using 1 & 2 to differentiate between launchpads
  launchpad1:set_event_callback(function (event) handle_event(event, 1) end)
  launchpad2:set_event_callback(function (event) handle_event(event, 2) end)

  clock.run(test)
end

-- encoder callback
function enc(n,d)
end

-- key callback
function key(n,z)
  if z == 1 then
    if n == 2 then
      -- k2 turns on disco mode
      launchpad1:disco()
      launchpad2:disco()
    elseif n == 3 then
      -- k3 turns all pads off
      launchpad1:all_pads_off()
      launchpad2:all_pads_off()
    end
  end
end

-- update screen
function redraw()
end

-- called when script unloads
function cleanup()
end