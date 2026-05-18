# toggl.nvim

Wrapper around [watercooler-labs/toggl-cli](https://github.com/watercooler-labs/toggl-cli) (>= v0.5.0) to offer:

- authentication
- configuration file management
- start/stop time entries
- edit time entry descriptions
- view current time entry
- list recent time entries

The commands can either be used with either `:Toggl<command>` or `:Toggl <subcommand>`

| Command | Subcommand | Description |
| --- | --- | --- |
| `TogglAuth` | `auth` | Authenticate with Toggl. Not required if `TOGGL_API_TOKEN` is set |
| `TogglConfig` | `config` | Edit the configuration file |
| `TogglCurrent` | `current` | Show the current time entry |
| `TogglInit` | `init` | Initialize configuration file |
| `TogglStart <description>` | `start <description>` | Start a new time entry with the given description |
| `TogglStop` | `stop` | Stop the current time entry |
| `TogglList <n>` | `list <n>` | List recent time entries, defaults to 5 |
| `TogglEdit` | `edit` | Edit the description of the running (or most recent) time entry |

The default behavior is `Toggl <subcommand>` unless `use_subcommands` is set to `false` in the plugin options.

### Health check

Run `:checkhealth toggl` to verify your setup:

- displays the installed `toggl` CLI version and checks it meets the minimum (v0.5.0)
- warns if the CLI is too old for `edit` support
- checks that `TOGGL_API_TOKEN` is set or authentication is configured

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

Requires Neovim >= 0.10.0 and [toggl-cli](https://github.com/watercooler-labs/toggl-cli) >= v0.5.0.
