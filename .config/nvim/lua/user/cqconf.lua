---
-- Utility functions
---
_G.util = {}

local uv = vim.loop

util.check_back_space = function()
  local col = vim.fn.col('.') - 1
  if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
    return true
  else
    return false
  end
end

util.write_file = function(path, contents)
  local fd = assert(uv.fs_open(path, 'w', 438))
  uv.fs_write(fd, contents, -1)
  assert(uv.fs_close(fd))
end

util.read_file = function(path)
  local fd = assert(uv.fs_open(path, 'r', 438))
  local fstat = assert(uv.fs_fstat(fd))
  local contents = assert(uv.fs_read(fd, fstat.size, 0))
  assert(uv.fs_close(fd))
  return contents
end

