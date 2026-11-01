local M = {}

function M.log_error(err)
  vim.notify(err.message, vim.log.levels.ERROR)
end

return M
