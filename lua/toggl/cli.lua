---@class TogglCommandOpts
---@field opts? TogglRuntimeOpts
---@field args? table
---@field [integer]? string
---@field [string]? any

---@class TogglGlobalOpts: TogglCommandOpts
---@field fzf? boolean
---@field help? boolean
---@field version? boolean
---@field C? string
---@field proxy? string

---@class TogglListCmd
---@field project fun(opts?: TogglCommandOpts): TogglProcessResult
---@field [string] any

---@class TogglConfigCmd
---@field init fun(opts?: TogglCommandOpts): TogglProcessResult
---@field [string] any

---@class TogglCli
---@field auth fun(opts?: TogglCommandOpts): TogglProcessResult
---@field config TogglConfigCmd
---@field continue fun(opts?: TogglCommandOpts): TogglProcessResult
---@field current fun(opts?: TogglCommandOpts): TogglProcessResult
---@field delete fun(opts?: TogglCommandOpts): TogglProcessResult
---@field edit fun(opts?: TogglCommandOpts): TogglProcessResult
---@field list TogglListCmd
---@field logout fun(opts?: TogglCommandOpts): TogglProcessResult
---@field running fun(opts?: TogglCommandOpts): TogglProcessResult
---@field start fun(opts?: TogglCommandOpts): TogglProcessResult
---@field stop fun(opts?: TogglCommandOpts): TogglProcessResult
---@field [string] any

---@type TogglCli
local toggl = require("toggl.process").factory "toggl"

return toggl
