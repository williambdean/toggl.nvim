# toggl.nvim

Wrapper around [watercooler-labs/toggl-cli](https://github.com/watercooler-labs/toggl-cli) to offer:

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
    },
}

```
