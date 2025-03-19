local health = require("toggl.health")
local Job = require("plenary.job")
local M = {}

local notify = function(msg, level)
  if msg == nil then
    return
  end

  vim.notify(msg, level, { title = "Toggl" })
end

local log = {
  info = function(msg)
    notify(msg, vim.log.levels.INFO)
  end,
  error = function(msg)
    notify(msg, vim.log.levels.ERROR)
  end,
}

local partial = function(fn, ...)
  local args = { ... }
  return function(...)
    return fn(unpack(args), ...)
  end
end

function M.toggl_auth(get_token)
  local token = get_token()
  if token == "" then
    log.error("Please provide a token")
    return
  end

  Job:new({
    command = "toggl",
    args = { "auth", token },
    on_stdout = function(_, result)
      log.info(result)
    end,
    on_stderr = function(_, result)
      log.error(result)
    end,
  }):start()
end

local function surrounded(str, char)
  return str:sub(1, 1) == char and str:sub(-1) == char
end

local function remove_surrounding_quotes(str)
  if surrounded(str, '"') or surrounded(str, "'") then
    return str:sub(2, -2)
  end

  return str
end

function M.toggl_start(opts)
  local description = opts.args
  description = remove_surrounding_quotes(description)
  if #description == 0 then
    log.error("Please provide a description")
    return
  end

  Job:new({
    command = "toggl",
    args = { "start", description },
    on_stdout = function(_, result)
      log.info(result)
    end,
    on_stderr = function(_, result)
      log.error(result)
    end,
  }):start()
end

function M.toggl_init()
  Job:new({
    command = "toggl",
    args = { "config", "init" },
    on_stdout = function(_, result)
      log.info(result)
    end,
    on_stderr = function(_, result)
      log.info(result)
    end,
  }):start()
end

function M.toggl_config()
  -- Assume the config exists until proven otherwise
  local config_exists = true

  Job:new({
    command = "toggl",
    args = { "config", "--path" },
    on_stdout = function(_, result)
      if not config_exists then
        return
      end

      result = vim.trim(result)
      if result == "" then
        return
      end

      if result:match("No config file found") then
        log.info("Run TogglInit to initialize config.")
        config_exists = false
        return
      end

      if not result:match("%.toml$") then
        log.error("Invalid config path")
        return
      end

      local path = result
      log.info("Config path: " .. path)
      vim.schedule(function()
        vim.cmd("tabnew " .. vim.fn.fnameescape(path))
      end)
    end,
    on_stderr = function(_, result)
      log.error(result)
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        log.error("Failed to get config path")
      end
    end,
  }):start()
end

function M.toggl_current()
  Job:new({
    command = "toggl",
    args = { "current" },
    on_stdout = function(_, result)
      log.info(result)
    end,
    on_stderr = function(_, result)
      log.error(result)
    end,
  }):start()
end

function M.toggl_stop()
  Job:new({
    command = "toggl",
    args = { "stop" },
    on_stdout = function(_, result)
      log.info(result)
    end,
    on_stderr = function(_, result)
      log.error(result)
    end,
  }):start()
end

function M.setup(opts)
  M.config = opts or {}
  opts.get_token = opts.get_token or function()
    return ""
  end

  vim.api.nvim_create_user_command("TogglInit", M.toggl_init, {})
  vim.api.nvim_create_user_command("TogglConfig", M.toggl_config, {})
  vim.api.nvim_create_user_command("TogglStart", M.toggl_start, { nargs = "*" })
  vim.api.nvim_create_user_command("TogglCurrent", M.toggl_current, {})
  vim.api.nvim_create_user_command("TogglStop", M.toggl_stop, {})
  if health.greater_than_480() and health.has_toggl_api_token() then
    return
  end
  vim.api.nvim_create_user_command(
    "TogglAuth",
    partial(M.toggl_auth, opts.get_token),
    {}
  )
end

return M
