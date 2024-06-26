local format = require("cmp_copilot.format")
local util = require("copilot.util")
local api = require("copilot.api")

local methods = { opts = {} }

methods.getCompletionsCycling = function(self, params, callback)
  local respond_callback = function(err, response)
    if err or not response or not response.completions then
      return callback({ isIncomplete = true, items = {} })
    end

    local indent = params.context.cursor_before_line:find("%S") or 1

    local items = vim.tbl_map(function(item)
      local ret = format.format_item(item, params.context, methods.opts)

      ret.textEdit.insert.start.character = ret.textEdit.insert.start.character + indent - 1
      ret.textEdit.newText = ret.textEdit.newText:sub(indent)
      if
        ret.textEdit.insert["end"].character < ret.textEdit.insert.start.character
        and ret.textEdit.insert["end"].line == ret.textEdit.insert.start.line
      then
        ret.textEdit.insert["end"].character = ret.textEdit.insert.start.character
      end
      ret.textEdit.newText = ret.textEdit.newText:gsub("%s+$", "")
      return ret
    end, vim.tbl_values(response.completions))

    return callback({
      isIncomplete = methods.opts.update_on_keypress,
      items = items,
    })
  end

  api.get_completions_cycling(self.client, util.get_doc_params(), respond_callback)
end

methods.init = function(completion_method, opts)
  methods.opts = vim.tbl_extend("force", methods.opts, opts or {})
  return methods[completion_method]
end

return methods
