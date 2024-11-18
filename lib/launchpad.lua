Launchpad = {}
Launchpad.__index = Launchpad

function Launchpad:rotate_grid(orig)
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

function Launchpad:merge_grid(full, grid)
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
  _lp.grid_notes = Launchpad:merge_grid(config.grid_notes, config.inner_grid)
  -- unrotated grid
  _lp.orig_notes = Launchpad:merge_grid(config.grid_notes, config.inner_grid)

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
    rotated = Launchpad:rotate_grid(rotated)
  end
  self.grid_notes = Launchpad:merge_grid(self.orig_notes, rotated)
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

return Launchpad