-- agent_board.lua
--
-- A herdr-like board for terminal sessions (mainly deol):
-- a sidebar listing every terminal buffer with a live state,
-- so multiple AI CLIs can be monitored without cycling tabs.
--
-- States come from output activity, tracked by polling each
-- terminal buffer's changedtick:
--   working : output within the last few seconds
--   idle    : quiet (most likely waiting for input)
--   exited  : the job has ended
--
-- Board keys: <CR> jump, x kill session, q close, r refresh,
-- and the spawn keys in AGENTS below (new tab + deol + command).

local M = {}

local WORKING_WINDOW_MS = 2500
local POLL_MS = 1000
local BOARD_FT = 'agentboard'
local BOARD_WIDTH = 44

-- Spawn presets shown in the board header.
local AGENTS = {
	{ key = 'g', label = 'gemini', command = 'gemini' },
	{ key = 'r', label = 'reviewer', command = 'gemini' },
	{ key = 's', label = 'shell', command = nil },
}

local state = {
	ticks = {}, -- bufnr -> last seen changedtick
	last_active = {}, -- bufnr -> uv.now() when output last seen
	board_buf = nil,
	timer = nil,
	prev_win = nil,
	line_map = {}, -- board line number -> bufnr
	started = false,
}

local function is_terminal(buf)
	return vim.api.nvim_buf_is_valid(buf)
		and vim.bo[buf].buftype == 'terminal'
end

local function terminal_bufs()
	local bufs = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if is_terminal(buf) then
			table.insert(bufs, buf)
		end
	end
	table.sort(bufs)
	return bufs
end

local function job_running(buf)
	local chan = vim.bo[buf].channel
	if not chan or chan <= 0 then
		return false
	end
	local ok, res = pcall(vim.fn.jobwait, { chan }, 0)
	return ok and res[1] == -1
end

local function derive_label(buf)
	local label = vim.b[buf].agent_board_label
	if label and label ~= '' then
		return label
	end
	-- Terminal buffers are named "term://<cwd>//<pid>:<command>".
	local name = vim.api.nvim_buf_get_name(buf)
	local cwd = name:match('^term://(.+)//%d+:.*$')
	if cwd then
		return vim.fn.fnamemodify(cwd, ':~')
	end
	return name
end

local function tail_line(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, -31, -1, false)
	for i = #lines, 1, -1 do
		local line = vim.trim(lines[i])
		if line ~= '' then
			local trimmed = false
			while vim.fn.strdisplaywidth(line) > 37 do
				line = vim.fn.strcharpart(line, 0, vim.fn.strchars(line) - 1)
				trimmed = true
			end
			if trimmed then
				line = line .. '…'
			end
			return line
		end
	end
	return ''
end

local function fmt_age(ms)
	local sec = math.floor(ms / 1000)
	if sec < 60 then
		return sec .. 's'
	end
	return math.floor(sec / 60) .. 'm'
end

local function sessions()
	local now = vim.uv.now()
	local list = {}
	for _, buf in ipairs(terminal_bufs()) do
		local status, age
		if not job_running(buf) then
			status = 'exited'
		elseif state.last_active[buf]
			and now - state.last_active[buf] <= WORKING_WINDOW_MS then
			status = 'working'
		else
			status = 'idle'
		end
		if state.last_active[buf] and state.last_active[buf] > 0 then
			age = fmt_age(now - state.last_active[buf])
		end
		table.insert(list, {
			bufnr = buf,
			label = derive_label(buf),
			status = status,
			age = age,
			tail = tail_line(buf),
		})
	end
	return list
end

local function poll()
	for _, buf in ipairs(terminal_bufs()) do
		local tick = vim.b[buf].changedtick
		if state.ticks[buf] == nil then
			-- First sight: do not mistake it for fresh output.
			state.ticks[buf] = tick
			if state.last_active[buf] == nil then
				state.last_active[buf] = 0
			end
		elseif state.ticks[buf] ~= tick then
			state.ticks[buf] = tick
			state.last_active[buf] = vim.uv.now()
		end
	end
end

local MARKS = { working = '●', idle = '○', exited = '×' }

local function render()
	local buf = state.board_buf
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local wins = vim.fn.win_findbuf(buf)
	if #wins == 0 then
		return
	end
	local win = wins[1]

	local keys = {}
	for _, agent in ipairs(AGENTS) do
		table.insert(keys, agent.key .. ':' .. agent.label)
	end
	local lines = {
		'Agents  ' .. table.concat(keys, ' ') .. '  <CR>:jump e:edit x:kill q:close',
		'',
	}
	local line_map = {}
	for _, s in ipairs(sessions()) do
		local head = string.format(
			'%s %-7s #%d %s%s',
			MARKS[s.status],
			s.status,
			s.bufnr,
			s.label,
			s.age and ('  (' .. s.age .. ')') or ''
		)
		table.insert(lines, head)
		line_map[#lines] = s.bufnr
		if s.tail ~= '' then
			table.insert(lines, '    ' .. s.tail)
			line_map[#lines] = s.bufnr
		end
	end
	if #lines == 2 then
		table.insert(lines, '(no terminal sessions)')
	end
	state.line_map = line_map

	local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	if cursor_line > #lines then
		cursor_line = #lines
	end
	vim.api.nvim_win_set_cursor(win, { cursor_line, 0 })
end

local function board_win()
	if state.board_buf and vim.api.nvim_buf_is_valid(state.board_buf) then
		local win = vim.fn.bufwinid(state.board_buf)
		if win ~= -1 then
			return win
		end
	end
	return nil
end

local function jump()
	local buf = state.line_map[vim.api.nvim_win_get_cursor(0)[1]]
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local wins = vim.fn.win_findbuf(buf)
	if #wins > 0 then
		vim.api.nvim_set_current_win(wins[1])
	else
		local target = state.prev_win
		if not target or not vim.api.nvim_win_is_valid(target)
			or vim.api.nvim_win_get_tabpage(target) ~= vim.api.nvim_get_current_tabpage()
			or vim.api.nvim_win_get_buf(target) == state.board_buf then
			target = nil
			local best_width = -1
			for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
				if vim.api.nvim_win_get_buf(win) ~= state.board_buf
					and vim.api.nvim_win_get_config(win).relative == '' then
					local width = vim.api.nvim_win_get_width(win)
					if width > best_width then
						best_width = width
						target = win
					end
				end
			end
		end
		if target then
			vim.api.nvim_win_set_buf(target, buf)
			vim.api.nvim_set_current_win(target)
		else
			vim.cmd('rightbelow vsplit')
			vim.api.nvim_win_set_buf(0, buf)
		end
	end
	if is_terminal(buf) then
		vim.cmd('startinsert')
	end
end

local function jump_edit()
	local buf = state.line_map[vim.api.nvim_win_get_cursor(0)[1]]
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local wins = vim.fn.win_findbuf(buf)
	if #wins == 0 then
		jump()
		return
	end
	local tab = vim.api.nvim_win_get_tabpage(wins[1])
	vim.api.nvim_set_current_tabpage(tab)
	-- A deol tab pairs its terminal with a deol-edit window;
	-- that input buffer is what 'e' should land on.
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
		local b = vim.api.nvim_win_get_buf(win)
		if vim.bo[b].filetype == 'deol-edit' then
			vim.api.nvim_set_current_win(win)
			vim.cmd('startinsert')
			return
		end
	end
	-- No edit window yet: focus the terminal and let deol's
	-- own 'e' mapping open the edit buffer. Normal mode first,
	-- or the 'e' would be typed into the terminal job.
	vim.api.nvim_set_current_win(wins[1])
	vim.cmd('stopinsert')
	vim.api.nvim_feedkeys('e', 'm', false)
end

local function kill()
	local buf = state.line_map[vim.api.nvim_win_get_cursor(0)[1]]
	if buf and vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
		render()
	end
end

local function spawn(agent)
	-- The board keeps the cursor: remember where we are, spawn
	-- in a new tab, then come straight back.
	local home_win = board_win()
	local home_tab = home_win
		and vim.api.nvim_win_get_tabpage(home_win) or nil
	local home_line = home_win
		and vim.api.nvim_win_get_cursor(home_win)[1] or nil
	-- Snapshot before tabnew: deol converts the new tab's empty
	-- buffer into the terminal, so it must count as "new" too.
	local before = {}
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		before[b] = true
	end
	vim.cmd('tabnew')
	-- Same base options as the deol hook's deol_command (an
	-- empty table would reach Vim as a List, not a Dictionary).
	vim.fn['deol#start']({
		edit = true,
		edit_filetype = 'deol-edit',
		prompt_pattern = '> ',
	})
	-- With edit=true, deol leaves the cursor in the edit buffer;
	-- the new terminal buffer is the one that just appeared.
	local buf = nil
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if not before[b] and is_terminal(b) then
			buf = b
		end
	end
	if buf then
		vim.b[buf].agent_board_label = agent.label
		state.ticks[buf] = vim.b[buf].changedtick
		state.last_active[buf] = vim.uv.now()
		if agent.command then
			local chan = vim.bo[buf].channel
			if chan and chan > 0 then
				-- Wait a moment for the shell prompt before typing.
				vim.defer_fn(function()
					if vim.api.nvim_buf_is_valid(buf) then
						pcall(vim.fn.chansend, chan, agent.command .. '\r')
					end
				end, 300)
			end
		end
	end
	-- Back to the board; the new session appears in the list.
	if home_win and vim.api.nvim_win_is_valid(home_win) then
		vim.cmd('stopinsert')
		vim.api.nvim_set_current_tabpage(home_tab)
		vim.api.nvim_set_current_win(home_win)
		if home_line then
			pcall(vim.api.nvim_win_set_cursor,
				home_win, { home_line, 0 })
		end
	end
	render()
end

local function open()
	state.prev_win = vim.api.nvim_get_current_win()
	if not state.board_buf or not vim.api.nvim_buf_is_valid(state.board_buf) then
		local buf = vim.api.nvim_create_buf(false, true)
		state.board_buf = buf
		vim.bo[buf].filetype = BOARD_FT
		vim.bo[buf].buftype = 'nofile'
		vim.bo[buf].bufhidden = 'wipe'
		vim.bo[buf].swapfile = false
		vim.bo[buf].modifiable = false

		local opt = { noremap = true, silent = true, buffer = buf }
		vim.keymap.set('n', '<CR>', jump, opt)
		vim.keymap.set('n', 'e', jump_edit, opt)
		vim.keymap.set('n', 'x', kill, opt)
		vim.keymap.set('n', 'q', function() M.toggle() end, opt)
		for _, agent in ipairs(AGENTS) do
			vim.keymap.set('n', agent.key, function() spawn(agent) end, opt)
		end
	end
	vim.cmd('topleft vertical split')
	vim.api.nvim_win_set_buf(0, state.board_buf)
	vim.api.nvim_win_set_width(0, BOARD_WIDTH)
	vim.wo.winfixwidth = true
	vim.wo.number = false
	vim.wo.signcolumn = 'no'
	vim.wo.cursorline = true
	render()
end

function M.toggle()
	local win = board_win()
	if win then
		pcall(vim.api.nvim_win_close, win, true)
	else
		open()
	end
end

function M.setup()
	if state.started then
		return
	end
	state.started = true
	local timer = vim.uv.new_timer()
	state.timer = timer
	timer:start(POLL_MS, POLL_MS, vim.schedule_wrap(function()
		poll()
		render()
	end))
	vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
		callback = function(ev)
			state.ticks[ev.buf] = nil
			state.last_active[ev.buf] = nil
		end,
	})
end

-- Exposed for tests.
M._sessions = sessions
M._render = render
M._poll = poll

return M
