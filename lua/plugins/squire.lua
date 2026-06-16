local opencode_go = {}

local function extract_text(decoded)
  local choice = decoded
    and decoded.choices
    and decoded.choices[1]

  local content = choice
    and choice.message
    and choice.message.content

  if type(content) == "string" then
    return content
  end

  if type(content) == "table" then
    local parts = {}

    for _, part in ipairs(content) do
      if type(part) == "string" then
        table.insert(parts, part)
      elseif type(part) == "table"
        and type(part.text) == "string"
      then
        table.insert(parts, part.text)
      end
    end

    if #parts > 0 then
      return table.concat(parts, "")
    end
  end

  return nil
end

local function sanitize_completion_text(text)
  if type(text) ~= "string" then
    return nil
  end

  local sanitized = text
    :gsub("<think>.-</think>", "")
    :gsub("\r", "")

  local clean_bytes = {}

  for i = 1, #sanitized do
    local byte = sanitized:byte(i)

    if byte == 9 or byte == 10 or (byte >= 32 and byte ~= 127) then
      table.insert(clean_bytes, string.char(byte))
    end
  end

  sanitized = table.concat(clean_bytes)
  sanitized = sanitized:gsub("^\n+", "")

  if not sanitized:match("%S") then
    return nil
  end

  return sanitized
end

local function build_healthcheck_config(config)
  local ping_config = vim.tbl_extend("force", config, {
    temperature = 0,
  })

  ping_config.max_tokens = math.max(
    tonumber(config.max_tokens) or 0,
    64
  )

  return ping_config
end

local auto_trigger_state = {
  enabled = true,
  timer = nil,
  bufnr = nil,
}

local function cancel_auto_trigger()
  if auto_trigger_state.timer then
    auto_trigger_state.timer:stop()

    if not auto_trigger_state.timer:is_closing() then
      auto_trigger_state.timer:close()
    end

    auto_trigger_state.timer = nil
  end

  auto_trigger_state.bufnr = nil
end

local function trigger_auto_completion(bufnr)
  local squire = require("squire")
  local config = require("squire.config")

  if not auto_trigger_state.enabled then
    return
  end

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if vim.api.nvim_get_current_buf() ~= bufnr then
    return
  end

  if not config.is_enabled_filetype(
    vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  ) then
    return
  end

  if not vim.api.nvim_get_mode().mode:match("^i") then
    return
  end

  if squire.has_suggestion() then
    return
  end

  squire.trigger_completion()
end

local function schedule_auto_trigger(bufnr, debounce_ms)
  if not auto_trigger_state.enabled then
    return
  end

  cancel_auto_trigger()

  auto_trigger_state.bufnr = bufnr
  auto_trigger_state.timer = vim.uv.new_timer()
  auto_trigger_state.timer:start(
    debounce_ms,
    0,
    vim.schedule_wrap(function()
      cancel_auto_trigger()
      trigger_auto_completion(bufnr)
    end)
  )
end

local function register_auto_trigger(debounce_ms)
  local group = vim.api.nvim_create_augroup(
    "SquireAutoTrigger",
    { clear = true }
  )

  vim.api.nvim_create_autocmd("TextChangedI", {
    group = group,
    callback = function(args)
      local squire = require("squire")

      if squire.has_suggestion() then
        squire.dismiss_suggestion()
      end

      schedule_auto_trigger(args.buf, debounce_ms)
    end,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
    group = group,
    callback = function()
      cancel_auto_trigger()
    end,
  })
end

local function register_auto_trigger_commands()
  pcall(vim.api.nvim_del_user_command, "SquireAutoEnable")
  pcall(vim.api.nvim_del_user_command, "SquireAutoDisable")

  vim.api.nvim_create_user_command(
    "SquireAutoEnable",
    function()
      auto_trigger_state.enabled = true
      vim.notify("Squire auto-completion enabled", vim.log.levels.INFO)
    end,
    { desc = "enable squire auto completion" }
  )

  vim.api.nvim_create_user_command(
    "SquireAutoDisable",
    function()
      auto_trigger_state.enabled = false
      cancel_auto_trigger()
      vim.notify("Squire auto-completion disabled", vim.log.levels.INFO)
    end,
    { desc = "disable squire auto completion" }
  )
end

local function register_healthcheck_command()
  pcall(vim.api.nvim_del_user_command, "SquireHealthcheck")

  vim.api.nvim_create_user_command(
    "SquireHealthcheck",
    function()
      vim.notify(
        "Squire: running healthcheck...",
        vim.log.levels.INFO
      )

      local squire = require("squire")
      local config = squire.get_config()

      if not config.api_key or config.api_key == "" then
        vim.notify(
          "Squire: app OK, but API key is not configured (set SQUIRE_LLM_API_KEY)",
          vim.log.levels.ERROR
        )
        return
      end

      local ok, current_provider = pcall(
        require("squire.provider").get,
        config.provider
      )

      if not ok then
        vim.notify(
          "Squire: app OK, API FAILED — "
            .. tostring(current_provider),
          vim.log.levels.ERROR
        )
        return
      end

      current_provider.complete(
        build_healthcheck_config(config),
        "ping",
        "Respond with the single word: pong",
        function(err, _)
          if err then
            vim.notify(
              "Squire: app OK, API FAILED — " .. err,
              vim.log.levels.ERROR
            )
          else
            vim.notify(
              "Squire: app OK, API OK",
              vim.log.levels.INFO
            )
          end
        end
      )
    end,
    { desc = "run healthcheck on squire app" }
  )
end

function opencode_go.complete(
  config,
  prompt_text,
  system_text,
  callback
)
  local curl = require("plenary.curl")

  local body = {
    model = config.model or "deepseek-v4-flash",

    messages = {
      {
        role = "system",
        content = system_text,
      },
      {
        role = "user",
        content = prompt_text,
      },
    },

    temperature = config.temperature or 0.2,
    max_tokens = config.max_tokens or 512,
    stream = false,
  }

  curl.post(
    config.base_url
      or "https://opencode.ai/zen/go/v1/chat/completions",
    {
      body = vim.fn.json_encode(body),

      headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] =
          "Bearer " .. (config.api_key or ""),
      },

      timeout = config.timeout_ms or 30000,

      callback = function(response)
        vim.schedule(function()
          local status = tonumber(response.status) or 0

          if status < 200 or status >= 300 then
            callback(
              string.format(
                "HTTP %s — %s",
                tostring(response.status),
                tostring(response.body)
              ),
              nil
            )
            return
          end

          local ok, decoded = pcall(
            vim.fn.json_decode,
            response.body
          )

          if not ok or type(decoded) ~= "table" then
            callback(
              "Failed to parse OpenCode Go response",
              nil
            )
            return
          end

          local text = sanitize_completion_text(
            extract_text(decoded)
          )

          if not text then
            callback(
              "No completion text in response",
              nil
            )
            return
          end

          callback(nil, text)
        end)
      end,

      on_error = function(err)
        vim.schedule(function()
          callback(
            "Request failed: " .. vim.inspect(err),
            nil
          )
        end)
      end,
    }
  )
end

----------------------------------------------------------------------
-- Register OpenCode Go in Squire
----------------------------------------------------------------------

local provider = require("squire.provider")
local original_get = provider.get

provider.get = function(name)
  if name == "opencode_go" then
    return opencode_go
  end

  return original_get(name)
end

----------------------------------------------------------------------
-- Configure Squire
----------------------------------------------------------------------

require("squire").setup({
  provider = "opencode_go",

  api_key = os.getenv("SQUIRE_LLM_API_KEY"),

  base_url =
    "https://opencode.ai/zen/go/v1/chat/completions",

  model = "minimax-m3",

  temperature = 0.2,
  max_tokens = 512,
  timeout_ms = 30000,

  debug = true,

  keymaps = {
    manual = "<C-Space>",
    accept = "<C-l>",
    dismiss = "<Esc>",
  },

  trigger_filetypes = {
    "go",
    "lua",
    "python",
    "javascript",
    "typescript",
    "typescriptreact",
    "javascriptreact",
    "rust",
    "bash",
    "sh",
    "json",
    "yaml",
    "markdown",
    "lua"
  },
})

register_healthcheck_command()
register_auto_trigger_commands()
register_auto_trigger(400)

-- Many terminals represent Ctrl-Space as Ctrl-@
vim.keymap.set(
  { "i", "n" },
  "<C-@>",
  "<Cmd>SquireComplete<CR>",
  {
    silent = true,
    desc = "Squire completion fallback",
  }
)
