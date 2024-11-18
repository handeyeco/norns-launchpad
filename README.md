> [!CAUTION]
> Currently very experimental and only supporting LP Mini MK3 (because that's all I have). Let me know if you're interested in testing other Launchpads.

# Norns Launchpad

Chances are if you found this repo, you were actually looking for midigrid (either [miker2049's](https://github.com/miker2049/midigrid) or [jaggednz's](https://github.com/jaggednz/midigrid)).

This is a lib for controlling Launchpads from [Norns](https://monome.org/docs/norns/).

Why? 🤷‍♂️ I wanted more color.

## API

### Launchpad:create(midi_index, config)

``` Lua
lp = Launchpad:create(1, getMiniMK3Config())
```

Bootstraps a Launchpad element.

- `midi_index` is a number representing the MIDI vport for the Launchpad.
- `config` is the specific configuration for the Launchpad model

### Launchpad:set_event_callback(cb)

``` Lua
lp:set_event_callback(function (data) tab.print(data) end)
```

Sets the callback function the Launchpad object will call when there's an interaction with the Launchpad. The data table looks like:

``` Lua
-- grid pressed
{
  type = "grid_pressed" | "grid_released",
  x = number,
  y = number,
}

-- control pressed
{
  type = "control_pressed" | "control_released",
  control = string,
  note = number,
}

-- other
{
  type = "other"
}
```

The tables also include a `midi` table which is the original MIDI message received from the Launchpad.

### Launchpad:set_grid_rotation(r)

Rotates the 8x8 grid (not the controls). Useful for putting multiple Launchpads next to one another to make a larger grid. `r` should 0 (none), 1, 2, or 3.

``` Lua
-- 270 degree rotation
lp:set_grid_rotation(3)
```

### pad_on and pad_off

Different ways of turning on and off pads on the Launchpad.

``` Lua
lp:note_pad_on(99, 3, 1)
lp:note_pad_off(99)

lp:coord_pad_on(1, 1, 3, 1)
lp:coord_pad_off(1, 1)

lp:grid_pad_on(1, 1, 3, 1)
lp:grid_pad_off(1, 1)
```

- `note_pad_on(note, color, behavior)` and `note_pad_off(note)`
  - low-level, direct access
  - `note` is the MIDI note number used to identify the pad
  - `color` (optional) number (0-127) representing the color to light the pad
  - `behavior` (optional) 1 is solid, 2 is flashing, 3 is pulsing
- `coord_pad_on(x, y, color, behavior)` and `coord_pad_off(x, y)`
  - x/y access (1-indexed)
  - includes control pads
  - does not respect grid rotation
  - `x` is the vertical axis (1-9)
  - `y` is the horizontal axis (1-9)
- `grid_pad_on(x, y, color, behavior)` and `grid_pad_off(x, y)`
  - x/y access (1-indexed)
  - does not include control pads
  - does respect grid rotation
  - `x` is the vertical axis (1-8)
  - `y` is the horizontal axis (1-8)

For colors, note layout, and behavior explanations, read the Launchpad programmer's reference for the device you're controlling.

### Launchpad:send(raw_data)

A way of sending raw MIDI data to the device. You probably don't need this.

### Launchpad:all_pads_off()

Turns all of the pads off.

``` Lua
lp:all_pads_off()
```

### Launchpad:disco()

Turns all pads on with different colors and behaviors.

``` Lua
lp:disco()
```