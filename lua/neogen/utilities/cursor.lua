neogen.utilities.cursor = {}

local neogen_ns = vim.api.nvim_create_namespace("neogen")
local neogen_virt_text_ns = vim.api.nvim_create_namespace("neogen_virt_text")
local current_position = 1

--- Wrapper around set_extmark with 1-based numbering for `line` and `col`, and returns the id of the created extmark
--- @param line string
--- @param col string
--- @return number
neogen.utilities.cursor.create = function(line, col, delimiters)
    local opts = delimiters == true and {}
        or { virt_text = { { "TODO", "TSTitle" } }, virt_text_pos = "overlay", virt_text_hide = true }
    current_position = 1
    local new_col = col == 0 and 0 or col - 1
    -- vim.api.nvim_buf_set_extmark(0, neogen_virt_text_ns, line - 1, new_col, opts)
    return vim.api.nvim_buf_set_extmark(0, neogen_ns, line - 1, new_col, {})
end

--- Find next created extmark and goes to it.
--- It removes the extmark afterwards.
--- First jumpable extmark is the one after the extmarks responsible of start/end of annotation
neogen.utilities.cursor.go_next_extmark = function()
    local extm_list = vim.api.nvim_buf_get_extmarks(0, neogen_ns, 0, -1, {})
    local virt_text_extm = vim.api.nvim_buf_get_extmarks(0, neogen_virt_text_ns, 0, -1, {})
    local position = current_position + 1

    if #extm_list ~= 2 then
        local pos = { extm_list[position][2] + 1, extm_list[position][3] }
        local virt_text = vim.tbl_filter(function(e)
            return e[2] == extm_list[position][2] and e[3] == extm_list[position][3]
        end, virt_text_extm)[1]
        if virt_text and #virt_text > 0 then
            vim.api.nvim_buf_del_extmark(0, neogen_virt_text_ns, virt_text[1])
        end

        vim.api.nvim_win_set_cursor(0, pos)
        current_position = current_position + 1
        return true
    else
        return false
    end
end

--- Goes to next extmark and start insert mode.
--- If `opts.first_time` is supplied, will try to go to normal mode before going to extmark
--- @param opts table
neogen.utilities.cursor.jump = function(opts)
    opts = opts or {}

    -- This is weird, the first time nvim goes to insert is not the same as when i'm already on insert mode
    -- that's why i put a first_time flag
    if opts.first_time then
        vim.api.nvim_command("startinsert")
    end

    if neogen.utilities.cursor.go_next_extmark() then
        vim.api.nvim_command("startinsert")
    end
end

neogen.utilities.cursor.jump_prev = function()
    local marks = vim.api.nvim_buf_get_extmarks(0, neogen_ns, 0, -1, {})

    if #marks == 2 then
        return false
    end

    local position = current_position - 1
    local pos = { marks[position][2] + 1, marks[position][3] }
    vim.api.nvim_win_set_cursor(0, pos)
    current_position = current_position - 1
    return true
end

--- Delete all active extmarks
neogen.utilities.cursor.del_extmarks = function()
    local extmarks = vim.api.nvim_buf_get_extmarks(0, neogen_ns, 0, -1, {})
    for _, v in pairs(extmarks) do
        vim.api.nvim_buf_del_extmark(0, neogen_ns, v[1])
    end
end

--- Checks if there are still possible jump positions to perform
--- Verifies if the cursor is in the last annotated part
neogen.utilities.cursor.jumpable = function(reverse)
    local extm_list = vim.api.nvim_buf_get_extmarks(0, neogen_ns, 0, -1, {})
    if #extm_list == 0 then
        return false
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    if cursor[1] > extm_list[#extm_list][2] or cursor[1] < extm_list[1][2] then
        return false
    end

    -- We arrive at the end, we can't jump anymore
    if current_position == #extm_list then
        return false
    end

    if reverse == -1 then
        -- Check first boundaries
        if current_position == 2 then
            return false
        end
    end

    if #extm_list > 2 then
        return true
    else
        return false
    end
end
