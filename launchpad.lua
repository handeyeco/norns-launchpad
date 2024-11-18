-- launchpad

Launchpad = {}
Launchpad.__index = Launchpad

function getMiniMK3Config()
  local control = {
    UP = 91,
    DOWN = 92,
    LEFT = 93,
    RIGHT = 94,
    SESSION = 95,
    DRUMS = 96,
    KEYS = 97,
    USER = 98,
    LOGO = 99,
    ROW_1 = 89,
    ROW_2 = 79,
    ROW_3 = 69,
    ROW_4 = 59,
    ROW_5 = 49,
    ROW_6 = 39,
    ROW_7 = 29,
    ROW_8 = 19,
  }

  local grid_notes = {
    {
      control.UP,
      control.DOWN,
      control.LEFT,
      control.RIGHT,
      control.SESSION,
      control.DRUMS,
      control.KEYS,
      control.USER,
      control.LOGO
    },
    {0, 0, 0, 0, 0, 0, 0, 0, control.ROW_1},
    {0, 0, 0, 0, 0, 0, 0, 0, control.ROW_2},
    {0, 0, 0, 0, 0, 0, 0, 0, control.ROW_3},
    {0, 0, 0, 0, 0, 0, 0, 0, control.ROW_4},
    {0, 0, 0, 0, 0, 0, 0, 0, control.ROW_5},
    {0, 0, 0, 0, 0, 0, 0, 0, control.ROW_6},
    {0, 0, 0, 0, 0, 0, 0, 0, control.ROW_7},
    {0, 0, 0, 0, 0, 0, 0, 0, control.ROW_8}
  }

  local inner_grid = {
    {81, 82, 83, 84, 85, 86, 87, 88},
    {71, 72, 73, 74, 75, 76, 77, 78},
    {61, 62, 63, 64, 65, 66, 67, 68},
    {51, 52, 53, 54, 55, 56, 57, 58},
    {41, 42, 43, 44, 45, 46, 47, 48},
    {31, 32, 33, 34, 35, 36, 37, 38},
    {21, 22, 23, 24, 25, 26, 27, 28},
    {11, 12, 13, 14, 15, 16, 17, 18}
  }

  return {
    control = control,
    grid_notes = grid_notes,
    inner_grid = inner_grid
  }
end

function rotate_grid(orig)
  local n = 8
  local ret = {}

  for i = 1, n, 1 do
    ret[i] = {}
  end

  for i = 1, n, 1 do
    for j = 1, n, 1 do
      ret[i][j] = orig[n - j + 1][i]
    end
  end

  return ret
end

function merge_grid(full, grid)
  local ret = {}

  -- copy original
  for i = 1, 9, 1 do
    ret[i] = {}
    for j = 1, 9, 1 do
      ret[i][j] = full[i][j]
    end
  end

  -- merge
  for i = 1, 8, 1 do
    for j = 1, 8, 1 do
      ret[i+1][j] = grid[i][j]
    end
  end

  return ret
end

function Launchpad:create(midi_index, config)
  local _lp = {}
  setmetatable(_lp, Launchpad)

  -- stash internal data
  -- grid that rotation is applied to
  _lp.grid_notes = merge_grid(config.grid_notes, config.inner_grid)
  -- unrotated grid
  _lp.orig_notes = merge_grid(config.grid_notes, config.inner_grid)

  _lp.orig_inner_grid = config.inner_grid
  _lp.control = config.control

  -- init
  _lp.midi_connection = midi.connect(midi_index)
  _lp.grid_rotation = 0
  _lp:_programmer_mode()

  return _lp
end

function Launchpad:_programmer_mode()
  self:send{240, 0, 32, 41, 2, 13, 14, 1, 247}
end

-- take a MIDI message and transform it into something
-- with more semantic meaning
function Launchpad:_transform_midi_event(data, cb)
  local message = midi.to_msg(data)

  local event = {
    type = "other",
    midi = message
  }
  
  if message.type == "note_on" or message.type == "note_off" then
    local event_type = (message.type == "note_on" and message.vel > 0)
      and "grid_pressed"
      or "grid_released"

    -- handle grid rotation
    local grid_x
    local grid_y
    for y = 2, 9, 1 do
      for x = 1, 8, 1 do
        if self.grid_notes[y][x] == message.note then
          grid_x = x
          grid_y = y-1
        end
      end
    end

    event = {
      type = event_type,
      x = grid_x,
      y = grid_y,
    }
  elseif (message.type == "cc") then
    local event_type = message.val > 0
      and "control_pressed"
      or "control_released"

    local control_name
    for k,v in pairs(self.control) do
      if (v == message.cc) then
        control_name = k
      end
    end

    event = {
      type = event_type,
      control = control_name,
      note = message.cc,
    }
  end

  tab.print(event)

  return event
end

function Launchpad:set_event_callback(cb)
  self.midi_connection.event = function(data)
    local event = self:_transform_midi_event(data, cb)
    return cb(event)
  end
end

function Launchpad:set_grid_rotation(r)
  local rot = (r or 0) % 4
  self.grid_rotation = rot
  local rotated = self.orig_inner_grid
  for i=1, rot, 1 do
    rotated = rotate_grid(rotated)
  end
  self.grid_notes = merge_grid(self.orig_notes, rotated)
end

function Launchpad:note_pad_on(note, _color, _behavior)
  local color = _color or 3
  local behavior = _behavior or 1
  self.midi_connection:note_on(note, color, behavior)
end

function Launchpad:note_pad_off(note)
  self.midi_connection:note_off(note, 0, 1)
end

-- color is the number associated with the color in the manual
-- behavior is static (1), flashing (2), and pulsing (2)
function Launchpad:coord_pad_on(x, y, _color, _behavior)
  local note = self.orig_notes[y][x]
  self:note_pad_on(note, _color, _behavior)
end

function Launchpad:coord_pad_off(x, y)
  local note = self.orig_notes[y][x]
  self:note_pad_off(note)
end

function Launchpad:grid_pad_on(x, y, _color, _behavior)
  local note = self.grid_notes[y+1][x]
  self:note_pad_on(note, _color, _behavior)
end

function Launchpad:grid_pad_off(x, y)
  local note = self.grid_notes[y+1][x]
  self:note_pad_off(note)
end

function Launchpad:control_pad_on(name, _color, _behavior)
  local note
  for k,v in pairs(self.control) do
    if k == name then
      note = v
    end
  end
  self:note_pad_on(note, _color, _behavior)
end

function Launchpad:control_pad_off(name)
  local note
  for k,v in pairs(self.control) do
    if k == name then
      note = v
    end
  end
  self:note_pad_off(note)
end

function Launchpad:all_pads_off()
  for i = 1, 9, 1 do
    for j = 1, 9, 1 do
      self:coord_pad_off(i, j)
    end
  end
end

function Launchpad:disco()
  for i = 1, 9, 1 do
    for j = 1, 9, 1 do
      local color = math.random(0, 127)
      local behavior = math.random(3)
      self:coord_pad_on(i, j, color, behavior)
    end
  end
end

function Launchpad:send(raw_data)
  self.midi_connection:send(raw_data)
end

-- NORNS LIFECYCLE CALLBACKS
-- NORNS LIFECYCLE CALLBACKS
-- NORNS LIFECYCLE CALLBACKS

midi_devices = {}

launchpad1 = nil
launchpad2 = nil

function handle_event(event, lp_index)
  if not event then return end

  local main_lp = lp_index == 1 and launchpad1 or launchpad2
  local mirr_lp = lp_index == 2 and launchpad1 or launchpad2

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
  build_midi_device_list()
  launchpad1 = Launchpad:create(3, getMiniMK3Config())
  launchpad2 = Launchpad:create(4, getMiniMK3Config())
  launchpad1:all_pads_off()
  launchpad2:all_pads_off()

  launchpad1:set_grid_rotation(3)
  launchpad2:set_grid_rotation(0)

  launchpad1:set_event_callback(function (event) handle_event(event, 1) end)
  launchpad2:set_event_callback(function (event) handle_event(event, 2) end)

  clock.run(test)
end

function test()
  launchpad1:control_pad_on("LOGO", 33, 3)
  launchpad2:control_pad_on("LOGO", 33, 3)

  launchpad1:control_pad_on("UP")
  launchpad1:control_pad_on("DOWN")
  launchpad1:control_pad_on("LEFT")
  launchpad1:control_pad_on("RIGHT")
  launchpad2:control_pad_on("UP")
  launchpad2:control_pad_on("DOWN")
  launchpad2:control_pad_on("LEFT")
  launchpad2:control_pad_on("RIGHT")

  clock.sleep(1)

  launchpad1:control_pad_off("UP")
  launchpad1:control_pad_off("DOWN")
  launchpad1:control_pad_off("LEFT")
  launchpad1:control_pad_off("RIGHT")
  launchpad2:control_pad_off("UP")
  launchpad2:control_pad_off("DOWN")
  launchpad2:control_pad_off("LEFT")
  launchpad2:control_pad_off("RIGHT")

  -- rotated, grid only
  for y = 1, 8, 1 do
    for x = 1, 16, 1 do
      local lp = x < 9 and launchpad1 or launchpad2
      local mapped_x = x < 9 and x or x - 8
      lp:grid_pad_on(mapped_x, y)
      clock.sleep(0.03)
      lp:grid_pad_off(mapped_x, y)
    end
  end

  -- unrotated, full
  for y = 1, 9, 1 do
    for x = 1, 18, 1 do
      local lp = x < 10 and launchpad1 or launchpad2
      local mapped_x = x < 10 and x or x - 9
      lp:coord_pad_on(mapped_x, y)
      clock.sleep(0.03)
      lp:coord_pad_off(mapped_x, y)
    end
  end
end

-- encoder callback
function enc(n,d)
end

-- key callback
function key(n,z)
  if z then
    if n == 2 then
      launchpad1:disco()
      launchpad2:disco()
    elseif n == 3 then
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

function build_midi_device_list()
  midi_devices = {}
  for i = 1, #midi.vports do
    local long_name = midi.vports[i].name
    local short_name = string.len(long_name) > 15 and util.acronym(long_name) or long_name
    table.insert(midi_devices, short_name)
  end
end