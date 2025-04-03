--- Adapted from octo.nvim
local Job = require("plenary.job")
local log = require("toggl.log")

local M = {}

local conf = {
  timeout = 10000,
}

function M.is_blank(s)
  return (
    s == nil
    or s == vim.NIL
    or (type(s) == "string" and string.match(s, "%S") == nil)
    or (type(s) == "table" and next(s) == nil)
  )
end

function M.create_callback(opts)
  opts = opts or {}

  opts.success = opts.success or log.info
  opts.failure = opts.failure or log.error

  return function(output, stderr)
    if stderr and not M.is_blank(stderr) then
      opts.failure(stderr)
    elseif output then
      opts.success(output)
    end
  end
end

M.run = function(opts)
  opts = opts or {}

  if M.is_blank(opts.cb) then
    opts.cb = M.create_callback({})
  end

  local mode = opts.mode or "async"
  local job = Job:new({
    enable_recording = true,
    command = "toggl",
    args = opts.args,
    on_stdout = vim.schedule_wrap(function(err, data, _)
      if mode == "async" and opts.stream_cb then
        opts.stream_cb(data, err)
      end
    end),
    on_exit = vim.schedule_wrap(function(j_self, _, _)
      if mode == "async" and opts.cb then
        local output = table.concat(j_self:result(), "\n")
        local stderr = table.concat(j_self:stderr_result(), "\n")
        opts.cb(output, stderr)
      end
    end),
  })
  if mode == "sync" then
    job:sync(conf.timeout)
    return table.concat(job:result(), "\n"),
      table.concat(job:stderr_result(), "\n")
  else
    job:start()
  end
end

local create_flag = function(key)
  if #key == 1 then
    return "-" .. key
  else
    return "--" .. key
  end
end

M.insert_input = function(args, flag, parameter, key, value)
  if type(value) == "boolean" then
    value = tostring(value)
  end

  if type(value) == "table" then
    for k, v in pairs(value) do
      local new_parameter = type(key) == "number" and parameter .. "[]"
        or parameter .. "[" .. key .. "]"
      M.insert_input(args, flag, new_parameter, k, v)
    end
  elseif type(key) == "number" then
    table.insert(args, flag)
    table.insert(args, parameter .. "[]=" .. value)
  else
    table.insert(args, flag)
    table.insert(args, parameter .. "[" .. key .. "]=" .. value)
  end
end

---Insert the options into the args table
---@param args table the arguments table
---@param options table the options to insert
---@param replace table|nil key value pairs to replace in the key of the options
---@return table the updated args table
M.insert_args = function(args, options, replace)
  replace = replace or {}

  for key, value in pairs(options) do
    if type(key) == "number" then
      table.insert(args, value)
    else
      for k, v in pairs(replace) do
        key = string.gsub(key, k, v)
      end

      local flag = create_flag(key)

      if type(value) == "table" then
        for k, v in pairs(value) do
          if type(v) == "table" then
            for kk, vv in pairs(v) do
              M.insert_input(args, flag, k, kk, vv)
            end
          elseif type(v) == "boolean" then
            if v then
              table.insert(args, flag)
              table.insert(args, k .. "=" .. tostring(v))
            end
          else
            table.insert(args, flag)
            table.insert(args, k .. "=" .. v)
          end
        end
      elseif type(value) == "boolean" then
        if value then
          table.insert(args, flag)
        end
      else
        table.insert(args, flag)
        table.insert(args, value)
      end
    end
  end

  return args
end

local create_subcommand = function(command)
  local subcommand = {}
  local replace = { ["_"] = "-" }
  for k, v in pairs(replace) do
    command = string.gsub(command, k, v)
  end
  subcommand.command = command

  setmetatable(subcommand, {
    __call = function(t, opts)
      opts = opts or {}

      local run_opts = opts.opts or {}

      local args = {
        t.command,
      }

      opts.opts = nil
      args = M.insert_args(args, opts)

      return M.run({
        args = args,
        mode = run_opts.mode,
        cb = run_opts.cb,
        stream_cb = run_opts.stream_cb,
      })
    end,
    __index = function(t, key)
      for k, v in pairs(replace) do
        key = string.gsub(key, k, v)
      end

      return function(opts)
        opts = opts or {}

        local run_opts = opts.opts or {}

        local args = {
          t.command,
          key,
        }

        opts.opts = nil
        args = M.insert_args(args, opts)

        return M.run({
          args = args,
          mode = run_opts.mode,
          cb = run_opts.cb,
          stream_cb = run_opts.stream_cb,
        })
      end
    end,
  })

  return subcommand
end

setmetatable(M, {
  __index = function(_, key)
    return create_subcommand(key)
  end,
})

return M
