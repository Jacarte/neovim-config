-- Copilot LSP configuration for Sidekick
-- Uses copilot-language-server installed via Mason

return {
  cmd = { "copilot-language-server", "--stdio" },
  filetypes = {
    "go", "python", "javascript", "typescript", "lua", "rust", "c", "cpp",
    "java", "ruby", "php", "html", "css", "json", "yaml", "markdown", "bash", "sh"
  },
  root_markers = { ".git", "package.json", "go.mod", "Cargo.toml", "pyproject.toml" },
  settings = {},
}
