-- agent_board.lua
--
-- A herdr-like board for AI CLI sessions: a sidebar listing
-- the sessions it spawned, each with a live state, so several
-- CLIs can be monitored and driven from one tab.
--
-- Sessions are plain Neovim terminal buffers owned by the
-- board. They are created hidden -- no tab, no window -- and
-- shown one at a time in the main window beside the board.
-- (deol cannot do this: it keeps exactly one instance per
-- tab. The user's own deol usage is untouched by this board.)
--
-- States come from output activity, tracked by polling each
-- terminal buffer's changedtick:
--   working : output within the last few seconds
--   idle    : quiet (most likely waiting for input)
--   exited  : the job has ended
--
-- Board keys: <CR> show terminal, e compose input, x kill,
-- q close, and the spawn keys in AGENTS below. j/k move by
-- session (each takes two lines), the main window previews
-- the selected session without needing <CR>, and = restores
-- the board width after an accidental resize.
--
-- Each session has a compose buffer (e) for writing input
-- with the user's usual insert-mode setup (e.g. skkeleton),
-- since a raw terminal cannot offer that. Compose keys:
-- <CR> send the current line, S send the whole buffer as one
-- bracketed paste and clear it.

local M = {}

local WORKING_WINDOW_MS = 2500
local POLL_MS = 1000
local BOARD_FT = 'agentboard'
local COMPOSE_FT = 'agentboard-compose'
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
	compose = {}, -- terminal bufnr -> compose bufnr
	board_buf = nil,
	timer = nil,
	prev_win = nil,
	line_map = {}, -- board line number -> bufnr
	head_lines = {}, -- board lines that start a session entry
	preview_buf = nil, -- session currently previewed in main
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

-- Only sessions spawned from the board are managed (and
-- listed); they carry the board's label variable. Terminals
-- the user opened himself are not the board's business.
local function managed(buf)
	return vim.b[buf].agent_board_label ~= nil
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
		if managed(buf) then
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
	end
	return list
end

local function poll()
	for _, buf in ipairs(terminal_bufs()) do
		if managed(buf) then
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
		'Agents  ' .. table.concat(keys, ' ') .. '  <CR>:jump e:edit x:kill q:close =:size',
		'',
	}
	local line_map = {}
	local head_lines = {}
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
		table.insert(head_lines, #lines)
		if s.tail ~= '' then
			table.insert(lines, '    ' .. s.tail)
			line_map[#lines] = s.bufnr
		end
	end
	if #lines == 2 then
		table.insert(lines, '(no terminal sessions)')
	end
	state.line_map = line_map
	state.head_lines = head_lines

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

-- The window session content is shown in: the one that was
-- current when the board opened, else the widest ordinary
-- window of this tab, else a fresh split beside the board.
-- Windows showing a compose buffer are only a last resort
-- for other content: they are an input slot, not a display
-- slot (and the reverse when the target is a compose buffer:
-- the tab's compose slot is reused).
local function main_window(target_buf)
	local for_compose = target_buf ~= nil
		and vim.bo[target_buf].filetype == COMPOSE_FT
	local cur_tab = vim.api.nvim_get_current_tabpage()
	local function usable(win, allow_compose)
		return win and vim.api.nvim_win_is_valid(win)
			and vim.api.nvim_win_get_tabpage(win) == cur_tab
			and vim.api.nvim_win_get_buf(win) ~= state.board_buf
			and vim.api.nvim_win_get_config(win).relative == ''
			and (allow_compose
				or vim.bo[vim.api.nvim_win_get_buf(win)].filetype
					~= COMPOSE_FT)
	end
	if for_compose then
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			local b = vim.api.nvim_win_get_buf(win)
			if vim.bo[b].filetype == COMPOSE_FT then
				return win
			end
		end
	end
	if usable(state.prev_win, for_compose) then
		return state.prev_win
	end
	for _, allow_compose in ipairs(for_compose and { true } or { false, true }) do
		local best, best_width = nil, -1
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			if usable(win, allow_compose) then
				local width = vim.api.nvim_win_get_width(win)
				if width > best_width then
					best, best_width = win, width
				end
			end
		end
		if best then
			return best
		end
	end
	vim.cmd('rightbelow vsplit')
	local win = vim.api.nvim_get_current_win()
	vim.wo[win].winfixwidth = false
	vim.wo[win].signcolumn = 'auto'
	vim.wo[win].cursorline = false
	return win
end

local function show_in_main(buf)
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_get_buf(win) == buf then
			vim.api.nvim_set_current_win(win)
			return
		end
	end
	local win = main_window(buf)
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_set_current_win(win)
end

local function jump()
	local buf = state.line_map[vim.api.nvim_win_get_cursor(0)[1]]
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	show_in_main(buf)
	state.preview_buf = buf
	if is_terminal(buf) then
		vim.cmd('startinsert')
	end
end

local preview -- forward declaration; defined below

-- j/k move by session, not by line: each session takes a
-- status line and a tail line. From a tail line, k first
-- goes to that session's own status line.
local function move_selection(dir)
	local heads = state.head_lines
	if #heads == 0 then
		return
	end
	local sign = dir > 0 and 1 or -1
	local cur = vim.api.nvim_win_get_cursor(0)[1]
	local idx = 0
	for i, h in ipairs(heads) do
		if h <= cur then
			idx = i
		end
	end
	-- One step first (with the tail-line rule for k), then
	-- any extra count steps in the same direction.
	local target
	if sign > 0 then
		target = math.min(idx + 1, #heads)
	else
		if idx > 0 and heads[idx] == cur then
			target = math.max(idx - 1, 1)
		else
			target = math.max(idx, 1)
		end
	end
	target = target + sign * (math.abs(dir) - 1)
	target = math.max(1, math.min(target, #heads))
	vim.api.nvim_win_set_cursor(0, { heads[target], 0 })
	preview()
end

-- The main window follows the selection: moving in the board
-- previews the session under the cursor there, without
-- moving focus out of the board. Re-selecting the same
-- session is a no-op, so a compose view of it survives
-- wiggling between its two lines.
preview = function()
	local buf = state.line_map[vim.api.nvim_win_get_cursor(0)[1]]
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	if state.preview_buf == buf then
		return
	end
	state.preview_buf = buf
	local win = main_window(buf)
	if vim.api.nvim_win_get_buf(win) ~= buf then
		vim.api.nvim_win_set_buf(win, buf)
	end
end

-- Undo an accidental resize: the board goes back to its
-- fixed width and the main window takes the rest again.
local function reset_layout()
	local win = board_win()
	if win then
		vim.api.nvim_win_set_width(win, BOARD_WIDTH)
	end
end

-- The compose buffer of a session: a scratch buffer where
-- input is written with the usual insert-mode setup and then
-- sent to the session's channel.
local function session_chan(term_buf)
	if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
		return nil
	end
	if not job_running(term_buf) then
		return nil
	end
	local chan = vim.bo[term_buf].channel
	if chan and chan > 0 then
		return chan
	end
	return nil
end

local function compose_warn()
	vim.notify('agent_board: session is not running', vim.log.levels.WARN)
end

local function send_line(compose_buf)
	local chan = session_chan(vim.b[compose_buf].agent_board_session)
	if not chan then
		compose_warn()
		return
	end
	vim.fn.chansend(chan, vim.api.nvim_get_current_line() .. '\r')
	-- Step to the next line, appending a fresh one at the end,
	-- so consecutive lines can be sent one after another.
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local last = vim.api.nvim_buf_line_count(compose_buf)
	if lnum == last then
		vim.api.nvim_buf_set_lines(compose_buf, last, last, false, { '' })
	end
	vim.api.nvim_win_set_cursor(0, { lnum + 1, 0 })
end

local function send_all(compose_buf)
	local chan = session_chan(vim.b[compose_buf].agent_board_session)
	if not chan then
		compose_warn()
		return
	end
	local text = table.concat(
		vim.api.nvim_buf_get_lines(compose_buf, 0, -1, false), '\n')
	if text == '' then
		return
	end
	-- Bracketed paste: the whole text lands as one paste
	-- instead of one submit per line; the CR after the paste
	-- submits it.
	vim.fn.chansend(chan, '\27[200~' .. text .. '\27[201~\r')
	vim.api.nvim_buf_set_lines(compose_buf, 0, -1, false, { '' })
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

local function compose_for(term_buf)
	local c = state.compose[term_buf]
	if c and vim.api.nvim_buf_is_valid(c) then
		return c
	end
	c = vim.api.nvim_create_buf(false, true)
	state.compose[term_buf] = c
	vim.bo[c].buftype = 'nofile'
	vim.bo[c].bufhidden = 'hide'
	vim.bo[c].swapfile = false
	vim.bo[c].filetype = COMPOSE_FT
	vim.b[c].agent_board_session = term_buf
	local opt = { noremap = true, silent = true, buffer = c }
	vim.keymap.set('n', '<CR>', function() send_line(c) end, opt)
	vim.keymap.set('n', 'S', function() send_all(c) end, opt)
	return c
end

local function jump_edit()
	local buf = state.line_map[vim.api.nvim_win_get_cursor(0)[1]]
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	show_in_main(compose_for(buf))
	vim.cmd('startinsert')
end

local function kill()
	local buf = state.line_map[vim.api.nvim_win_get_cursor(0)[1]]
	if buf and vim.api.nvim_buf_is_valid(buf) then
		if state.preview_buf == buf then
			state.preview_buf = nil
		end
		local c = state.compose[buf]
		state.compose[buf] = nil
		if c and vim.api.nvim_buf_is_valid(c) then
			pcall(vim.api.nvim_buf_delete, c, { force = true })
		end
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
		render()
	end
end

-- A window to size a new terminal after: the one that was
-- current when the board opened, else any ordinary window of
-- this tab, else the board window itself.
local function host_window()
	local cur_tab = vim.api.nvim_get_current_tabpage()
	local function ok(win)
		return win and vim.api.nvim_win_is_valid(win)
			and vim.api.nvim_win_get_tabpage(win) == cur_tab
			and vim.api.nvim_win_get_buf(win) ~= state.board_buf
			and vim.api.nvim_win_get_config(win).relative == ''
	end
	if ok(state.prev_win) then
		return state.prev_win
	end
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if ok(win) then
			return win
		end
	end
	return board_win()
end

local function spawn(agent)
	local win = board_win()
	-- Create the terminal hidden: run termopen inside the new
	-- buffer via buf_call in a host window (which also gives
	-- the terminal a sensible initial size). No tab is made
	-- and the board keeps the cursor.
	local buf = vim.api.nvim_create_buf(false, true)
	local host = host_window()
	if host then
		vim.api.nvim_set_current_win(host)
	end
	local cwd = vim.fn.getcwd()
	vim.api.nvim_buf_call(buf, function()
		vim.fn.termopen(vim.o.shell, { cwd = cwd })
	end)
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
	if win and vim.api.nvim_win_is_valid(win) then
		vim.cmd('stopinsert')
		vim.api.nvim_set_current_win(win)
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
		vim.keymap.set('n', 'j', function() move_selection(vim.v.count1) end, opt)
		vim.keymap.set('n', 'k', function() move_selection(-vim.v.count1) end, opt)
		vim.keymap.set('n', '=', reset_layout, opt)
		vim.api.nvim_create_autocmd('CursorMoved', {
			buffer = buf,
			callback = preview,
		})
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
			-- A session buffer gone by other means takes its
			-- compose buffer with it.
			local c = state.compose[ev.buf]
			if c then
				state.compose[ev.buf] = nil
				if vim.api.nvim_buf_is_valid(c) then
					pcall(vim.api.nvim_buf_delete, c, { force = true })
				end
			end
		end,
	})
end

-- Exposed for tests.
M._sessions = sessions
M._render = render
M._poll = poll
M._compose_for = compose_for

return M
