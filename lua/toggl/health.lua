local M = {}
local toggl = require "toggl.cli"

local MIN_VERSION = "0.5.0"

local function parse_version(str)
  local major, minor, patch = str:match "(%d+)%.(%d+)%.(%d+)"
  if not major then
    return nil
  end
  return {
    major = tonumber(major),
    minor = tonumber(minor),
    patch = tonumber(patch),
    str = str:match "%S+",
  }
end

local function is_newer_version(version, min_version)
  local v = parse_version(version)
  local m = parse_version(min_version)
  if not v or not m then
    return false
  end

  return v.major > m.major
    or (v.major == m.major and v.minor > m.minor)
    or (v.major == m.major and v.minor == m.minor and v.patch >= m.patch)
end

---@return string|nil
function M.get_toggl_version()
  local result = toggl { version = true }
  if not result or not result:ok() then
    return nil
  end
  return result:text()
end

function M.has_toggl_cli()
  local result = toggl { version = true }
  return result and result:ok() or false
end

function M.has_toggl_api_token()
  return os.getenv "TOGGL_API_TOKEN" ~= nil
end

function M.meets_min_version()
  local version = M.get_toggl_version()
  if not version then
    return false
  end
  local trimmed = vim.trim(version):match "[%d%.]+"
  if not trimmed then
    return false
  end
  return is_newer_version(trimmed, MIN_VERSION)
end

function M.check()
  vim.health.start "toggl.nvim"

  if not M.has_toggl_cli() then
    vim.health.error "toggl CLI is not installed"
    return
  end

  local version = M.get_toggl_version()
  if version then
    local trimmed = vim.trim(version):match "[%d%.]+"
    local meets = trimmed and is_newer_version(trimmed, MIN_VERSION)
    if meets then
      vim.health.ok(("toggl v%s (min %s)"):format(trimmed, MIN_VERSION))
    else
      vim.health.warn(
        ("toggl v%s is installed, but v%s+ is required for edit support.\n          Upgrade at https://github.com/watercooler-labs/toggl-cli"):format(
          trimmed or version,
          MIN_VERSION
        )
      )
    end
  else
    vim.health.error "Could not determine toggl version"
    return
  end

  if M.has_toggl_api_token() then
    vim.health.ok "TOGGL_API_TOKEN is set"
  else
    vim.health.warn "TOGGL_API_TOKEN is not set — run :Toggl auth or set the environment variable"
  end
end

return M
