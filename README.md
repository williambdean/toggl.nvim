# toggl.nvim

Wrapper around [watercooler-labs/toggl-cli](https://github.com/watercooler-labs/toggl-cli) to offer:

- authentication
- configuration file management
- start/stop time entries
- view current time entry
- list recent time entries

The commands can either be used with either `:Toggl<command>` or `:Toggl <subcommand>`

| Command | Subcommand | Description |
| --- | --- | --- |
| `TogglAuth` | `auth` | Authenticate with Toggl. Not required if `TOGGL_API_TOKEN` is set |
| `TogglConfig` | `config` | Edit the configuration file |
| `TogglCurrent` | `current` | Show the current time entry |
| `ToggleInit` | `init` | Initialize configuration file |
| `TogglStart <description>` | `start <description>` | Start a new time entry with the given description |
| `TogglStop` | `stop` | Stop the current time entry |
| `TogglList <n>` | `list <n>` | List recent time entries, defaults to 5 |

The default behavior is `Toggl <subcommand>` unless `use_subcommands` is set to `false` in the plugin options.

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
