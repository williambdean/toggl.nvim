local health = require("toggl.health")
local Job = require("plenary.job")
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
		vim.notify("Please provide get_token function to opts.")
		return
	end

	Job:new({
		command = "toggl",
		args = { "auth", token },
		on_stdout = function(j, result)
			vim.notify(result)
		end,
		on_stderr = function(j, result)
			vim.notify(result, "error")
		end,
	}):start()
end

function M.toggl_start(opts)
	local description = opts.args

	if #description == 0 then
		vim.notify("Please provide a description")
		return
	end
	Job:new({
		command = "toggl",
		args = { "start", description },
		on_stdout = function(j, result)
			vim.notify(result)
		end,
		on_stderr = function(j, result)
			vim.notify(result, "error")
		end,
	}):start()
end

function M.toggl_config()
	Job:new({
		command = "toggl",
		args = { "config", "--path" },
		on_stdout = function(j, result)
			local path = vim.trim(result)
			if path == "" then
				return
			end

			if not path:match("%.toml$") then
				vim.notify("Invalid config path", "error")
				return
			end
			vim.notify("Config path: " .. path)
			vim.schedule(function()
				vim.cmd("edit " .. vim.fn.fnameescape(path))
			end)
		end,
		on_stderr = function(j, result)
			vim.notify(result, "error")
		end,
		on_exit = function(j, code)
			if code ~= 0 then
				vim.notify("Failed to get config path", "error")
			end
		end,
	}):start()
end

function M.toggl_current()
	Job:new({
		command = "toggl",
		args = { "current" },
		on_stdout = function(j, result)
			vim.notify(result)
		end,
		on_stderr = function(j, result)
			vim.notify(result, "error")
		end,
	}):start()
end

function M.toggl_stop()
	Job:new({
		command = "toggl",
		args = { "stop" },
		on_stdout = function(j, result)
			vim.notify(result)
		end,
		on_stderr = function(j, result)
			vim.notify(result)
		end,
	}):start()
end

function M.setup(opts)
	M.config = opts or {}
	opts.get_token = opts.get_token or function()
		return ""
	end

	vim.api.nvim_create_user_command("TogglConfig", M.toggl_config, {})
	vim.api.nvim_create_user_command("TogglStart", M.toggl_start, { nargs = "*" })
	vim.api.nvim_create_user_command("TogglCurrent", M.toggl_current, {})
	vim.api.nvim_create_user_command("TogglStop", M.toggl_stop, {})
	if not health.check_toggl_version() then
		return
	end
	vim.api.nvim_create_user_command("TogglAuth", partial(M.toggl_auth, opts.get_token), {})
end

return M
