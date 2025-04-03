local health = require("toggl.health")
local Job = require("plenary.job")
local log = require("toggl.log")

local M = {}

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

local copy = function(str, register)
  if register == nil then
    register = '"'
  end

  vim.fn.setreg(register, str)
  log.info("Copied " .. str .. " to register " .. register)
end

function M.projects()
  local opts = {}
  opts.cb = function(stdout, stderr)
    if stderr ~= "" then
      log.error(stderr)
    end

    if stdout ~= "" then
      local projects = vim.split(stdout, "\n")

      vim.ui.select(projects, {
        prompt = "Select a project:",
        format_item = function(item)
          return item
        end,
      }, function(selected)
        if selected then
          local project = vim.trim(selected)
          copy(project, "+")
        end
      end)
    end
  end

  Job:new({
    command = "toggl",
    args = { "list", "project" },
    on_exit = vim.schedule_wrap(function(j_self, _, _)
      local stdout = table.concat(j_self:result(), "\n")
      local stderr = table.concat(j_self:stderr_result(), "\n")
      opts.cb(stdout, stderr)
    end),
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
  vim.api.nvim_create_user_command("TogglProjects", M.projects, {})
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
