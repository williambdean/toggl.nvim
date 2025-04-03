local M = {}

M.notify = function(msg, level)
  if msg == nil then
    return
  end

  vim.notify(msg, level, { title = "Toggl" })
end

M.info = function(msg)
  M.notify(msg, vim.log.levels.INFO)
end

M.error = function(msg)
  M.notify(msg, vim.log.levels.ERROR)
end

return M
