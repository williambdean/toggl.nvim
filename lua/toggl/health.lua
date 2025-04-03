local M = {}

local function is_newer_version(version, min_version)
  local major, minor, patch = version:match "(%d+)%.(%d+)%.(%d+)"
  major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)

  local min_major, min_minor, min_patch =
    min_version:match "(%d+)%.(%d+)%.(%d+)"
  min_major, min_minor, min_patch =
    tonumber(min_major), tonumber(min_minor), tonumber(min_patch)

  return major > min_major
    or (major == min_major and minor > min_minor)
    or (major == min_major and minor == min_minor and patch >= min_patch)
end

function M.has_toggl_cli()
  local handle = io.popen "which toggl"
  local result = handle:read "*a"
  handle:close()

  return result ~= ""
end

function M.has_toggl_api_token()
  return os.getenv "TOGGL_API_TOKEN" ~= nil
end

function M.greater_than_480()
  local handle = io.popen "toggl --version"
  local result = handle:read "*a"
  handle:close()

  local min_version = "0.4.8"
  return is_newer_version(result, min_version)
end

function M.check()
  vim.health.start "Toggl.nvim"
  if not M.has_toggl_cli() then
    vim.health.error "Toggl is not installed"
    return
  end

  vim.health.ok "Toggl is installed"

  if M.greater_than_480() and M.has_toggl_api_token() then
    vim.health.ok "Toggl version check passed"
  elseif M.greater_than_480() and not M.has_toggl_api_token() then
    vim.health.warn "Set TOGGL_API_TOKEN environment variable to skip authentication"
  else
    vim.health.warn "Toggl version requires authentication with TogglAuth command"
  end
end

return M
