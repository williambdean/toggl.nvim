local health = require "toggl.health"
local log = require "toggl.log"
local toggl = require "toggl.cli"

local M = {}

local partial = function(fn, ...)
  local args = { ... }
  return function(...)
    return fn(unpack(args), ...)
  end
end

---@param result TogglProcessResult
local function log_result(result)
  if result:ok() then
    local data = result:text()
    if not data then
      return
    end
    log.info(data)
  else
    local data = result.stderr
    if data == "" then
      data = result:text()
    end
    if not data or data == "" then
      return
    end
    log.error(data)
  end
end

function M.toggl_auth(get_token)
  local token = get_token()
  if token == "" then
    log.error "Please provide a token"
    return
  end

  local result = toggl.auth { token }
  log_result(result)
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

function M.toggl_list(opts)
  local n = opts.args
  n = n ~= "" and n or 5

  local result = toggl.list { n = n }
  if not result then
    return
  end
  if not result:ok() then
    log_result(result)
    return
  end

  local data = result:text()
  if not data then
    return
  end

  data = "The last " .. n .. " Toggl entries:\n" .. data
  log.info(data)
end

function M.toggl_start(opts)
  local description = opts.args
  description = remove_surrounding_quotes(description)
  if #description == 0 then
    log.error "Please provide a description"
    return
  end

  local result = toggl.start { description }
  log_result(result)
end

function M.toggl_current()
  local result = toggl.current {}
  log_result(result)
end

function M.toggl_stop()
  local result = toggl.stop {}
  log_result(result)
end

function M.toggl_init()
  local result = toggl.config.init()
  log_result(result)
end

function M.toggl_config()
  local result = toggl.config { path = true }
  if not result then
    return
  end
  if not result:ok() then
    log_result(result)
    return
  end

  local stdout = result:text()
  if not stdout then
    return
  end

  if stdout:match "No config file found" then
    log.info "Run TogglInit or Toggl init to initialize config."
    return
  end

  if not stdout:match "%.toml$" then
    log.error "Invalid config path"
    return
  end

  local path = stdout
  log.info("Config path: " .. path)
  vim.cmd.tabnew(vim.fn.fnameescape(path))
end

local copy = function(str, register)
  if register == nil then
    register = '"'
  end

  vim.fn.setreg(register, str)
  log.info("Copied " .. str .. " to register " .. register)
end

function M.projects()
  local result = toggl.list.project {}
  if not result then
    return
  end
  if not result:ok() then
    log_result(result)
    return
  end

  local stdout = result:text()
  if not stdout then
    return
  end

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

local complete = function(_, cmdline, _)
  local args = vim.split(cmdline, " ")
  local last_arg = args[#args]

  if #args > 2 then
    return {}
  end

  local available_commands = {
    "auth",
    "config",
    "current",
    "init",
    "list",
    "projects",
    "start",
    "stop",
  }

  local completions = {}
  for _, command in ipairs(available_commands) do
    if command:sub(1, #last_arg) == last_arg then
      table.insert(completions, command)
    end
  end

  return completions
end
local execute_subcommand = function(command_opts, opts)
  local command = command_opts.fargs[1]
  local rest = vim.list_slice(command_opts.fargs, 2)

  if not command then
    return M.toggl_current()
  end

  -- Combine a table with " "
  local combined = table.concat(rest, " ")

  local func_mapping = {
    [""] = function()
      M.toggl_current()
    end,
    start = M.toggl_start,
    stop = M.toggl_stop,
    list = M.toggl_list,
    config = M.toggl_config,
    current = M.toggl_current,
    init = M.toggl_init,
    projects = M.projects,
    auth = partial(M.toggl_auth, opts.get_token),
  }
  local func = func_mapping[command]

  if func then
    func { args = combined }
  else
    log.error("Unknown command: " .. command)
  end
end

local default_config = {
  use_subcommands = true,
}

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", opts, default_config)

  --- TODO: Check the logic here
  opts.get_token = opts.get_token or function()
    return ""
  end

  if M.config.use_subcommands then
    vim.api.nvim_create_user_command("Toggl", function(command_opts)
      execute_subcommand(command_opts, opts)
    end, { complete = complete, nargs = "*", range = false })
  else
    vim.api.nvim_create_user_command("TogglInit", function()
      M.toggl_init()
    end, {})
    vim.api.nvim_create_user_command("TogglList", M.toggl_list, {
      nargs = "?",
      complete = "number",
      range = false,
      desc = "List recent Toggl entries",
    })
    vim.api.nvim_create_user_command("TogglConfig", M.toggl_config, {})
    vim.api.nvim_create_user_command(
      "TogglStart",
      M.toggl_start,
      { nargs = "*" }
    )
    vim.api.nvim_create_user_command("TogglCurrent", function()
      M.toggl_current()
    end, {})
    vim.api.nvim_create_user_command("TogglStop", function()
      M.toggl_stop()
    end, {})
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
end

return M
