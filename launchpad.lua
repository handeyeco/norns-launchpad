-- launchpad

Launchpad = {}
Launchpad.__index = Launchpad

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

grid_notes = {
  {91, 92, 93, 94, 95, 96, 97, 98, 99},
  {0, 0, 0, 0, 0, 0, 0, 0, 89},
  {0, 0, 0, 0, 0, 0, 0, 0, 79},
  {0, 0, 0, 0, 0, 0, 0, 0, 69},
  {0, 0, 0, 0, 0, 0, 0, 0, 59},
  {0, 0, 0, 0, 0, 0, 0, 0, 49},
  {0, 0, 0, 0, 0, 0, 0, 0, 39},
  {0, 0, 0, 0, 0, 0, 0, 0, 29},
  {0, 0, 0, 0, 0, 0, 0, 0, 19}
}

inner_grid = {
  {81, 82, 83, 84, 85, 86, 87, 88},
  {71, 72, 73, 74, 75, 76, 77, 78},
  {61, 62, 63, 64, 65, 66, 67, 68},
  {51, 52, 53, 54, 55, 56, 57, 58},
  {41, 42, 43, 44, 45, 46, 47, 48},
  {31, 32, 33, 34, 35, 36, 37, 38},
  {21, 22, 23, 24, 25, 26, 27, 28},
  {11, 12, 13, 14, 15, 16, 17, 18}
}

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

function Launchpad:create(midi_index)
  local _lp = {}
  setmetatable(_lp, Launchpad)

  -- stash internal data
  _lp.grid_notes = merge_grid(grid_notes, inner_grid)

  -- init
  _lp.midi_connection = midi.connect(midi_index)
  _lp.grid_rotation = 0
  _lp:programmer_mode()

  return _lp
end

function Launchpad:set_event_callback(cb)
  self.midi_connection.event = cb
end

function Launchpad:set_grid_rotation(r)
  local rot = (r or 0) % 4
  self.grid_rotation = rot
  local rotated = inner_grid
  for i=1, rot, 1 do
    rotated = rotate_grid(rotated)
  end
  self.grid_notes = merge_grid(grid_notes, rotated)

  for i=1,9,1 do
    local str = ""
    for j=1,9,1 do
      local num = self.grid_notes[i][j]
      str = str.." "..num
    end
    print(str)
  end
end

function Launchpad:programmer_mode()
  self:send{240, 0, 32, 41, 2, 13, 14, 1, 247}
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
  local note = self.grid_notes[y+1][x+1]
  self:note_pad_on(note, _color, _behavior)
end

function Launchpad:coord_pad_off(x, y)
  local note = self.grid_notes[y+1][x+1]
  self:note_pad_off(note)
end

function Launchpad:grid_pad_on(x, y, _color, _behavior)
  print("x: "..(x+1).." y: "..(y+2))
  local note = self.grid_notes[y+2][x+1]
  self:note_pad_on(note, _color, _behavior)
end

function Launchpad:grid_pad_off(x, y)
  local note = self.grid_notes[y+2][x+1]
  self:note_pad_off(note)
end

function Launchpad:all_pads_off()
  for i = 0, 8, 1 do
    for j = 0, 8, 1 do
      self:coord_pad_off(i, j)
    end
  end
end

function Launchpad:disco()
  for i = 0, 8, 1 do
    for j = 0, 8, 1 do
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

launchpad = nil
launchpad2 = nil

function handle_midi_event(data)
  local message = midi.to_msg(data)

  if message.type == "note_on" then
    launchpad:note_pad_on(message.note)
    launchpad2:note_pad_on(message.note)
  elseif message.type == "note_off" then
    launchpad:note_pad_off(message.note)
    launchpad2:note_pad_off(message.note)
  elseif message.type == "cc" then
    if message.val == 127 then
      launchpad:note_pad_on(message.cc)
      launchpad2:note_pad_on(message.cc)
    elseif message.val == 0 then
      launchpad:note_pad_off(message.cc)
      launchpad2:note_pad_off(message.cc)
    end
  end
end

-- called when script loads
function init()
  build_midi_device_list()
  launchpad = Launchpad:create(3)
  launchpad2 = Launchpad:create(4)

  launchpad:set_grid_rotation(3)
  print(" ")
  launchpad2:set_grid_rotation(0)

  launchpad:set_event_callback(handle_midi_event)
  launchpad2:set_event_callback(handle_midi_event)

  clock.run(light)
end

function light()
  for y = 0, 7, 1 do
    for x = 0, 7, 1 do
      launchpad:grid_pad_on(x,y)
      launchpad2:grid_pad_on(x,y)
      clock.sleep(0.05)
      launchpad:grid_pad_off(x,y)
      launchpad2:grid_pad_off(x,y)
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
      launchpad:disco()
      launchpad2:disco()
    elseif n == 3 then
      launchpad:all_pads_off()
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
    print(long_name)
    local short_name = string.len(long_name) > 15 and util.acronym(long_name) or long_name
    table.insert(midi_devices, short_name)
  end
end