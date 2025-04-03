local health = require "toggl.health"
local Job = require "plenary.job"
local log = require "toggl.log"
local toggl = require "toggl.cli"

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
    log.error "Please provide a token"
    return
  end

  toggl.auth { token }
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
    log.error "Please provide a description"
    return
  end

  toggl.start { description }
end

function M.toggl_config()
  -- Assume the config exists until proven otherwise
  local config_exists = true

  --- TODO: Handle the exit code
  toggl.config {
    path = true,
    opts = {
      stream_cb = toggl.create_callback {
        success = function(result)
          if not config_exists then
            return
          end

          result = vim.trim(result)
          if result == "" then
            return
          end

          if result:match "No config file found" then
            log.info "Run TogglInit to initialize config."
            config_exists = false
            return
          end

          if not result:match "%.toml$" then
            log.error "Invalid config path"
            return
          end

          local path = result
          log.info("Config path: " .. path)
          vim.cmd("tabnew " .. vim.fn.fnameescape(path))
        end,
      },
    },
  }
end

local copy = function(str, register)
  if register == nil then
    register = '"'
  end

  vim.fn.setreg(register, str)
  log.info("Copied " .. str .. " to register " .. register)
end

function M.projects()
  toggl.list.project {
    opts = {
      cb = toggl.create_callback {
        success = function(stdout)
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
        end,
      },
    },
  }
end

function M.setup(opts)
  M.config = opts or {}
  opts.get_token = opts.get_token or function()
    return ""
  end

  vim.api.nvim_create_user_command("TogglInit", toggl.config.init, {})
  vim.api.nvim_create_user_command("TogglConfig", M.toggl_config, {})
  vim.api.nvim_create_user_command("TogglStart", M.toggl_start, { nargs = "*" })
  vim.api.nvim_create_user_command("TogglCurrent", function()
    toggl.current {}
  end, {})
  vim.api.nvim_create_user_command("TogglStop", function()
    toggl.stop {}
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

return M
