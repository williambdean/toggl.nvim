# toggl.nvim

Wrapper around [watercooler-labs/toggl-cli](https://github.com/watercooler-labs/toggl-cli) to offer:

- authentication
- configuration file management
- start/stop time entries
- view current time entry

Based on configuration, the commands can either be used with either `:Toggl <subcommand>`

| Subcommand | Description |
| --- | --- |
| auth | Authenticate with Toggl. Not required if `TOGGL_API_TOKEN` is set |
| config | Edit the configuration file |
| current | Show the current time entry |
| init | Initialize configuration file |
| start <description> | Start a new time entry with the given description |
| stop | Stop the current time entry |

or with:

| Command | Description |
| --- | --- |
| `:TogglAuth` | Authenticate with Toggl. Not required if `TOGGL_API_TOKEN` is set |
| `:TogglConfig` | Edit the configuration file |
| `:TogglCurrent` | Show the current time entry |
| `:TogglInit` | Initialize configuration file |
| `:TogglStart <description>` | Start a new time entry with the given description |
| `:TogglStop` | Stop the current time entry |


## Installation

Using your favorite plugin manager, add the following:

```lua
{
    "williambdean/toggl.nvim",
    opts = {
        -- If not provided in TOGGL_API_TOKEN env variable
        get_token = function()
            return "your_toggl_api_token",
        end,
        -- Use Toggl <subcommand> over Toggl<command>
        use_subcommands = true,
    },
}

```
