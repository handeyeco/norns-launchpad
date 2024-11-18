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

return getMiniMK3Config