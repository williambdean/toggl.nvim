--- Adapted from octo.nvim process module
local M = {}

---@class TogglResult
---@field code number The exit code
---@field stdout string Combined stdout
---@field stderr string Combined stderr
---@field data string The primary output (stdout or stderr)
---@field json fun(): table Helper to decode JSON
---@field trim fun(): string Helper to trim primary output
---@field text fun(): string|nil Helper to trim primary output and return nil on empty
---@field ok fun(): boolean Helper to check exit code

---@class TogglRuntimeOpts
---@field stdin? string
---@field env? table<string, string|integer>
---@field timeout? number
---@field cwd? string
---@field dry_run? boolean

---@class TogglDryRunResult
---@field command string[]
---@field opts vim.SystemOpts
---@field timeout? number
---@field ok fun(): boolean

---@alias TogglProcessResult TogglResult|TogglDryRunResult

---@param text string
---@return table
local function json_decode_or_empty(text)
  local ok, decoded = pcall(vim.json.decode, text)
  return ok and decoded or {}
end

---@param obj vim.SystemCompleted
---@return TogglResult
local function wrap_res(obj)
  local result = {
    code = obj.code,
    stdout = obj.stdout or "",
    stderr = obj.stderr or "",
  }

  result.data = (result.code == 0 and result.stdout ~= "") and result.stdout
    or result.stderr

  result.json = function()
    return json_decode_or_empty(result.stdout)
  end

  result.trim = function()
    return vim.trim(result.data)
  end

  result.text = function()
    local text = vim.trim(result.data)
    if text == "" then
      return nil
    end
    return text
  end

  result.ok = function()
    return result.code == 0
  end

  return result
end

---@param bin string
---@param args string[]
---@param transformer_opts TogglRuntimeOpts
---@return TogglResult|TogglDryRunResult|nil
function M.run(bin, args, transformer_opts)
  transformer_opts = transformer_opts or {}

  local cmd = { bin, unpack(args) }
  local co = coroutine.running()

  local sys_opts = {
    text = true,
    stdin = transformer_opts.stdin,
    env = transformer_opts.env,
    cwd = transformer_opts.cwd,
  }

  if transformer_opts.dry_run then
    return {
      command = cmd,
      opts = sys_opts,
      timeout = transformer_opts.timeout,
      ok = function()
        return true
      end,
    }
  end

  local timeout = transformer_opts.timeout or 10000

  if not co then
    local obj = vim.system(cmd, sys_opts):wait(timeout)
    return wrap_res(obj)
  end

  vim.system(cmd, sys_opts, function(obj)
    local wrapped = wrap_res(obj)
    if co then
      vim.schedule(function()
        coroutine.resume(co, wrapped)
      end)
    end
  end)

  if co then
    ---@diagnostic disable-next-line: await-in-sync
    return coroutine.yield()
  end

  ---@diagnostic disable-next-line: return-type-mismatch
  return nil
end

---@param tbl table<string|integer, any>
---@param target string[]
local function append_formatted(tbl, target)
  for k, v in pairs(tbl) do
    if type(k) == "string" then
      local flag = (#k == 1 and "-" or "--") .. k:gsub("_", "-")
      if type(v) == "table" then
        ---@diagnostic disable-next-line: no-unknown
        for _, item in ipairs(v) do
          vim.list_extend(target, { flag, tostring(item) })
        end
      else
        table.insert(target, flag)
        if v ~= true then
          table.insert(target, tostring(v))
        end
      end
    end
  end
  for i = 1, math.huge do
    if tbl[i] == nil then
      break
    end
    table.insert(target, tostring(tbl[i]))
  end
end

---The "Standard" Transformer logic
---Handles: { flag = true } -> --flag, { f = "val" } -> -f val, { list = {1, 2} } -> --list 1 --list 2
---Reserved keys stripped from CLI output: opts, _stdin, args
---When args is present, a `--` separator is inserted before its contents
---@param path string[]
---@param opts table<string|integer, any>
---@return string[], TogglRuntimeOpts
function M.default_transformer(path, opts)
  opts = vim.deepcopy(opts or {})

  ---@type string[]
  local args = vim.deepcopy(path)
  ---@type table
  local runtime_opts = type(opts.opts) == "table" and opts.opts or {}

  if opts._stdin ~= nil and runtime_opts.stdin == nil then
    runtime_opts.stdin = opts._stdin
  end

  opts._stdin = nil
  opts.opts = nil

  ---@type table?
  local extra_args = opts.args
  opts.args = nil

  -- Strip any literal "--" from args since we auto-insert it below
  if extra_args ~= nil then
    ---@type table
    local cleaned = {}
    local pos = 1
    for i = 1, math.huge do
      if extra_args[i] == nil then
        break
      end
      if extra_args[i] ~= "--" then
        ---@diagnostic disable-next-line: no-unknown
        cleaned[pos] = extra_args[i]
        pos = pos + 1
      end
    end
    ---@diagnostic disable-next-line: no-unknown
    for k, v in pairs(extra_args) do
      if type(k) == "string" then
        ---@diagnostic disable-next-line: no-unknown
        cleaned[k] = v
      end
    end
    extra_args = cleaned
  end

  ---@type TogglRuntimeOpts
  local t_opts = {
    stdin = runtime_opts.stdin,
    env = runtime_opts.env,
    timeout = runtime_opts.timeout,
    cwd = runtime_opts.cwd,
    dry_run = runtime_opts.dry_run,
  }

  ---@diagnostic disable-next-line: no-unknown
  append_formatted(opts, args)

  if extra_args ~= nil and next(extra_args) ~= nil then
    table.insert(args, "--")
    ---@diagnostic disable-next-line: no-unknown
    append_formatted(extra_args, args)
  end

  return args, t_opts
end

---The Proxy Factory
---@param bin string
---@param transformer? fun(path: string[], opts: table): string[], TogglRuntimeOpts
---@return table
function M.factory(bin, transformer)
  transformer = transformer or M.default_transformer

  local function make_proxy(path)
    return setmetatable({}, {
      __index = function(_, key)
        ---@diagnostic disable-next-line: no-unknown
        local segment = key:gsub("_", "-")
        return make_proxy(vim.list_extend(vim.deepcopy(path), { segment }))
      end,
      __call = function(_, opts)
        opts = opts or {}
        ---@type string[], TogglRuntimeOpts
        local args, t_opts = transformer(path, opts)
        ---@type TogglResult|TogglDryRunResult
        return M.run(bin, args, t_opts)
      end,
    })
  end
  return make_proxy {}
end

return M
