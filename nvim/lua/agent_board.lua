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
-- q close, A resume a gemini session (opens the resume
-- picker in the main window), and the spawn keys in
-- AGENTS below. j/k move by
-- session (each takes two lines), the main window previews
-- the selected session without needing <CR>, and = restores
-- the board width after an accidental resize.
--
-- Each session has a compose buffer for writing input with
-- the user's usual insert-mode setup (e.g. skkeleton), since
-- a raw terminal cannot offer that. The compose buffer of
-- the selected session is always shown in a small input
-- strip under the main window, with the destination session
-- in its winbar; e moves focus there. Compose keys:
-- <CR> send the current line, S send the whole buffer as one
-- bracketed paste and clear it, q or <C-q> back to the board
-- (<C-q> also from insert mode).

local M = {}

local WORKING_WINDOW_MS = 2500
local POLL_MS = 1000
local BOARD_FT = 'agentboard'
local COMPOSE_FT = 'agentboard-compose'
local PICKER_FT = 'agentboard-picker'
local BOARD_WIDTH = 44
local STRIP_HEIGHT = 4

-- Spawn presets shown in the board header.
local AGENTS = {
	-- 'a', not 'g': a bare 'g' map would shadow every g-prefixed
	-- command (gt/gT/gg) in the board buffer.
	{ key = 'a', label = 'gemini', command = 'gemini' },
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
	picker = nil, -- resume picker state, while open
	resume_seq = 0, -- supersedes stale picker list jobs
	strip_win = nil, -- input strip window under the main window
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
				ref = vim.b[buf].agent_board_ref,
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

local sync_strip -- forward declaration; defined below

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
		'Agents  ' .. table.concat(keys, ' ') .. '  <CR>:jump e:edit x:kill q:close =:size A:resume',
		'',
	}
	local line_map = {}
	local head_lines = {}
	for _, s in ipairs(sessions()) do
		local head = string.format(
			'%s %-7s #%d %s%s%s',
			MARKS[s.status],
			s.status,
			s.bufnr,
			s.label,
			s.age and ('  (' .. s.age .. ')') or '',
			s.ref and (' [' .. s.ref .. ']') or ''
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
	sync_strip()
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
local function find_main_window(target_buf)
	local for_compose = target_buf ~= nil
		and vim.bo[target_buf].filetype == COMPOSE_FT
	local cur_tab = vim.api.nvim_get_current_tabpage()
	local function usable(win, allow_compose)
		return win and vim.api.nvim_win_is_valid(win)
			and win ~= state.strip_win
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
			if win ~= state.strip_win
				and vim.bo[b].filetype == COMPOSE_FT then
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
	return nil
end

local function main_window(target_buf)
	local win = find_main_window(target_buf)
	if win then
		return win
	end
	vim.cmd('rightbelow vsplit')
	local new_win = vim.api.nvim_get_current_win()
	vim.wo[new_win].winfixwidth = false
	vim.wo[new_win].signcolumn = 'auto'
	vim.wo[new_win].cursorline = false
	return new_win
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
local release_picker_window -- forward declaration; defined below

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
-- session does not touch the main window again.
preview = function()
	local buf = state.line_map[vim.api.nvim_win_get_cursor(0)[1]]
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	if state.preview_buf ~= buf then
		state.preview_buf = buf
		local win = main_window(buf)
		if vim.api.nvim_win_get_buf(win) ~= buf then
			vim.api.nvim_win_set_buf(win, buf)
		end
	end
	sync_strip()
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
	local function leave()
		local bw = board_win()
		if bw then
			vim.api.nvim_set_current_win(bw)
		end
	end
	vim.keymap.set('n', 'q', leave, opt)
	vim.keymap.set('n', '<C-q>', leave, opt)
	vim.keymap.set('i', '<C-q>', function()
		vim.cmd('stopinsert')
		leave()
	end, opt)
	return c
end

local function close_strip()
	local strip = state.strip_win
	state.strip_win = nil
	if strip and vim.api.nvim_win_is_valid(strip) then
		pcall(vim.api.nvim_win_close, strip, true)
	end
end

local function strip_label(term_buf)
	local label = vim.b[term_buf].agent_board_label or '?'
	local ref = vim.b[term_buf].agent_board_ref
	return string.format('送信先: #%d %s%s',
		term_buf, label, ref and (' [' .. ref .. ']') or '')
end

-- The input strip: a small window under the main window
-- that always shows the compose buffer of the session the
-- board points at (cursor session, else the previewed one,
-- else the first), so input can be written without hiding
-- the terminal. Its winbar names the destination, taken
-- from the buffer actually shown so it never lies.
sync_strip = function()
	local bw = board_win()
	if not bw then
		close_strip()
		return
	end
	local target = state.line_map[vim.api.nvim_win_get_cursor(bw)[1]]
	if not target or not vim.api.nvim_buf_is_valid(target) then
		target = state.preview_buf
	end
	if not target or not vim.api.nvim_buf_is_valid(target) then
		local first = state.head_lines[1]
		target = first and state.line_map[first] or nil
	end
	if not target then
		close_strip()
		return
	end
	-- No main window (e.g. it was closed): the strip has
	-- nothing to sit under.
	if not find_main_window(nil) then
		close_strip()
		return
	end
	local compose = compose_for(target)
	local strip = state.strip_win
	if strip and not vim.api.nvim_win_is_valid(strip) then
		strip = nil
		state.strip_win = nil
	end
	if not strip then
		local main = find_main_window(nil)
		if not main then
			return
		end
		strip = vim.api.nvim_win_call(main, function()
			vim.cmd('belowright split')
			return vim.api.nvim_get_current_win()
		end)
		state.strip_win = strip
		vim.api.nvim_win_set_height(strip, STRIP_HEIGHT)
		vim.wo[strip].winfixheight = true
		vim.wo[strip].number = false
		vim.wo[strip].signcolumn = 'no'
		vim.wo[strip].statusline = ' '
	end
	-- Never yank the buffer while the user is typing in it.
	if vim.api.nvim_get_current_win() ~= strip
		and vim.api.nvim_win_get_buf(strip) ~= compose then
		vim.api.nvim_win_set_buf(strip, compose)
	end
	local shown = vim.api.nvim_win_get_buf(strip)
	local sess = vim.b[shown].agent_board_session
	if sess and vim.api.nvim_buf_is_valid(sess) then
		vim.wo[strip].winbar = ' ' .. strip_label(sess)
	end
end

local function jump_edit()
	local buf = state.line_map[vim.api.nvim_win_get_cursor(0)[1]]
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	sync_strip()
	local strip = state.strip_win
	if strip and vim.api.nvim_win_is_valid(strip) then
		vim.api.nvim_set_current_win(strip)
		vim.cmd('startinsert')
	end
end

-- Delete a buffer without collapsing the layout: Neovim
-- closes any window displaying a deleted buffer (see
-- :h :bdelete), so windows showing it are first re-homed
-- to their alternate buffer (or a fresh empty one).
local function wipe_buffer(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	for _, win in ipairs(vim.fn.win_findbuf(buf)) do
		local alt = vim.api.nvim_win_call(win, function()
			return vim.fn.bufnr('#')
		end)
		if alt <= 0 or alt == buf or not vim.api.nvim_buf_is_valid(alt) then
			alt = vim.api.nvim_create_buf(true, false)
		end
		pcall(vim.api.nvim_win_set_buf, win, alt)
	end
	pcall(vim.api.nvim_buf_delete, buf, { force = true })
end

local function kill()
	local buf = state.line_map[vim.api.nvim_win_get_cursor(0)[1]]
	if buf and vim.api.nvim_buf_is_valid(buf) then
		if state.preview_buf == buf then
			state.preview_buf = nil
		end
		local c = state.compose[buf]
		state.compose[buf] = nil
		if c then
			wipe_buffer(c)
		end
		wipe_buffer(buf)
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

local function spawn(agent, command, ref, spawn_cwd)
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
	local cwd = spawn_cwd or vim.fn.getcwd()
	vim.api.nvim_buf_call(buf, function()
		vim.fn.termopen(vim.o.shell, { cwd = cwd })
	end)
	vim.b[buf].agent_board_label = agent.label
	if ref then
		vim.b[buf].agent_board_ref = ref
	end
	state.ticks[buf] = vim.b[buf].changedtick
	state.last_active[buf] = vim.uv.now()
	local send = command or agent.command
	if send then
		local chan = vim.bo[buf].channel
		if chan and chan > 0 then
			-- Wait a moment for the shell prompt before typing.
			vim.defer_fn(function()
				if vim.api.nvim_buf_is_valid(buf) then
					pcall(vim.fn.chansend, chan, send .. '\r')
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

-- Resume an existing gemini session: A opens a picker in
-- the main window right away, showing a loading line while
-- `gemini --list-sessions` runs (the CLI takes seconds).
-- Sessions belong to the current directory (gemini scopes
-- them per project), so the directory is captured once and
-- used for both the listing and the spawn. The list is
-- newest first and moves with j/k; <CR> resumes the entry
-- under the cursor -- by its full UUID when the bracketed
-- ID is one, else by its index (exact at that instant).
-- The first row is manual entry: i edits it in place, and
-- <CR> in insert mode confirms (a UUID, an index, or
-- "latest"); it is also the fallback when listing fails.
local function gemini_agent()
	for _, agent in ipairs(AGENTS) do
		if agent.key == 'a' then
			return agent
		end
	end
end

local function parse_sessions(lines)
	local found = {}
	for _, line in ipairs(lines) do
		local index, summary, age, id =
			line:match('^%s*(%d+)%.%s+(.-)%s+%((.-)%)%s+%[(.-)%]%s*$')
		if index then
			table.insert(found, {
				index = tonumber(index),
				summary = summary,
				age = age,
				id = id,
			})
		end
	end
	return found
end

local function resume_with(ref, display_ref, cwd)
	local agent = gemini_agent()
	if not agent then
		return
	end
	spawn(agent, 'gemini --resume ' .. ref, display_ref, cwd)
end

local function render_picker()
	local p = state.picker
	if not p or not vim.api.nvim_buf_is_valid(p.buf) then
		return
	end
	-- Keep text typed into the manual row across re-renders
	-- (the list may arrive while the user is editing it).
	-- Only a line that already carries the edit prefix is
	-- user input; the placeholder row is not.
	if p.editing then
		local line = vim.api.nvim_buf_get_lines(p.buf, 1, 2, false)[1]
		if line and line:sub(1, 3) == 'ID:' then
			p.edit_text = (line:gsub('^ID:%s*', ''))
		end
	end
	local lines = {
		'Resume gemini session  <CR>:resume i:input ID q:close',
	}
	local rows = {}
	if p.editing then
		table.insert(lines, 'ID: ' .. (p.edit_text or ''))
	else
		table.insert(lines, '[manual] i: enter a session ID / index / latest')
	end
	rows[#lines] = { kind = 'manual' }
	if p.loading then
		table.insert(lines, 'loading...')
	elseif p.load_error then
		table.insert(lines, '(could not list sessions; manual entry still works)')
	elseif #p.sessions == 0 then
		table.insert(lines, '(no sessions for this directory)')
	else
		-- Table-like rows: age, summary and session ID in
		-- aligned columns, measured in display width so
		-- Japanese summaries line up too.
		local win = vim.fn.bufwinid(p.buf)
		local total = win ~= -1 and vim.api.nvim_win_get_width(win) or 120
		local age_w, id_w, sum_w = 0, 0, 0
		for _, sess in ipairs(p.sessions) do
			age_w = math.max(age_w, vim.fn.strdisplaywidth(sess.age))
			id_w = math.max(id_w, vim.fn.strdisplaywidth(sess.id))
			sum_w = math.max(sum_w, vim.fn.strdisplaywidth(sess.summary))
		end
		local summary_w = math.min(
			sum_w, math.max(20, total - age_w - id_w - 4))
		local function pad(str, w)
			local d = vim.fn.strdisplaywidth(str)
			if d < w then
				return str .. string.rep(' ', w - d)
			end
			return str
		end
		local function trunc(str, w)
			while vim.fn.strdisplaywidth(str) > w - 1 do
				str = vim.fn.strcharpart(str, 0, vim.fn.strchars(str) - 1)
			end
			return str .. '…'
		end
		for _, sess in ipairs(p.sessions) do
			local summary = sess.summary
			if vim.fn.strdisplaywidth(summary) > summary_w then
				summary = trunc(summary, summary_w)
			end
			table.insert(lines, string.format(
				'%s  %s  [%s]',
				pad(sess.age, age_w),
				pad(summary, summary_w),
				sess.id))
			rows[#lines] = { kind = 'session', index = sess.index, id = sess.id }
		end
	end
	p.rows = rows
	-- Keep the cursor where it was (the list arriving
	-- mid-edit must not yank it to the top of the buffer).
	local win = vim.fn.bufwinid(p.buf)
	local cur
	if win ~= -1 then
		cur = vim.api.nvim_win_get_cursor(win)
	end
	vim.bo[p.buf].modifiable = true
	vim.api.nvim_buf_set_lines(p.buf, 0, -1, false, lines)
	vim.bo[p.buf].modifiable = p.editing
	if win ~= -1 and cur then
		cur[1] = math.min(cur[1], #lines)
		cur[2] = math.min(cur[2], #(lines[cur[1]] or ''))
		pcall(vim.api.nvim_win_set_cursor, win, cur)
	end
end

release_picker_window = function(p)
	if not vim.api.nvim_win_is_valid(p.win) then
		return
	end
	if p.created_win then
		pcall(vim.api.nvim_win_close, p.win, true)
	elseif vim.api.nvim_buf_is_valid(p.prev_buf) then
		pcall(vim.api.nvim_win_set_buf, p.win, p.prev_buf)
	end
end

local function close_picker()
	local p = state.picker
	if not p then
		return
	end
	state.picker = nil
	p.cancelled = true
	release_picker_window(p)
	if vim.api.nvim_buf_is_valid(p.buf) then
		pcall(vim.api.nvim_buf_delete, p.buf, { force = true })
	end
	local bw = board_win()
	if bw then
		vim.api.nvim_set_current_win(bw)
	end
end

local function picker_move(dir)
	local p = state.picker
	if not p or p.editing then
		return
	end
	local row_lines = {}
	for line in pairs(p.rows or {}) do
		table.insert(row_lines, line)
	end
	table.sort(row_lines)
	if #row_lines == 0 then
		return
	end
	local cur = vim.api.nvim_win_get_cursor(0)[1]
	local idx = 1
	for i, line in ipairs(row_lines) do
		if line <= cur then
			idx = i
		end
	end
	local target = math.max(1, math.min(idx + dir, #row_lines))
	vim.api.nvim_win_set_cursor(0, { row_lines[target], 0 })
end

local function start_edit()
	local p = state.picker
	if not p or p.editing then
		return
	end
	p.editing = true
	p.edit_text = ''
	render_picker()
	local win = vim.fn.bufwinid(p.buf)
	if win ~= -1 then
		vim.api.nvim_win_set_cursor(win, { 2, 4 })
	end
	vim.cmd('startinsert!')
end

local function cancel_edit()
	local p = state.picker
	if not p or not p.editing then
		return
	end
	p.editing = false
	p.edit_text = nil
	vim.cmd('stopinsert')
	render_picker()
	local win = vim.fn.bufwinid(p.buf)
	if win ~= -1 then
		vim.api.nvim_win_set_cursor(win, { 2, 0 })
	end
end

local function confirm_edit()
	local p = state.picker
	if not p or not p.editing then
		return
	end
	local line = vim.api.nvim_buf_get_lines(p.buf, 1, 2, false)[1] or ''
	local input = vim.trim((line:gsub('^ID:%s*', '')))
	if input == '' then
		cancel_edit()
		return
	end
	-- The value is typed into a terminal as a command;
	-- keep it to the characters a session ref can have,
	-- and never let it look like a gemini flag.
	if input:sub(1, 1) == '-' or not input:match('^[%w%-%.]+$') then
		vim.notify('agent_board: invalid session ID', vim.log.levels.WARN)
		return
	end
	p.editing = false
	vim.cmd('stopinsert')
	local cwd = p.cwd
	close_picker()
	resume_with(input, input, cwd)
end

local function picker_enter()
	local p = state.picker
	if not p or p.editing then
		return
	end
	local item = (p.rows or {})[vim.api.nvim_win_get_cursor(0)[1]]
	if not item then
		return
	end
	if item.kind == 'manual' then
		start_edit()
		return
	end
	-- A full UUID cannot drift; a prefix cannot be resumed
	-- by, so use the index.
	local ref = item.id
	if not (#ref == 36 and ref:match('^[%x%-]+$')) then
		ref = tostring(item.index)
	end
	local cwd = p.cwd
	close_picker()
	resume_with(ref, item.id, cwd)
end

local function spawn_resume()
	if state.picker then
		close_picker()
	end
	local cwd = vim.fn.getcwd()
	state.resume_seq = state.resume_seq + 1
	local win = find_main_window(nil)
	local created_win = false
	if not win then
		win = main_window(nil)
		created_win = true
	end
	local buf = vim.api.nvim_create_buf(false, true)
	local p = {
		buf = buf,
		win = win,
		prev_buf = vim.api.nvim_win_get_buf(win),
		created_win = created_win,
		cwd = cwd,
		seq = state.resume_seq,
		loading = true,
		sessions = {},
		editing = false,
		cancelled = false,
		rows = {},
	}
	state.picker = p
	vim.bo[buf].filetype = PICKER_FT
	vim.bo[buf].buftype = 'nofile'
	vim.bo[buf].bufhidden = 'wipe'
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	local opt = { noremap = true, silent = true, buffer = buf }
	vim.keymap.set('n', 'j', function() picker_move(vim.v.count1) end, opt)
	vim.keymap.set('n', 'k', function() picker_move(-vim.v.count1) end, opt)
	vim.keymap.set('n', '<CR>', picker_enter, opt)
	vim.keymap.set('n', 'i', start_edit, opt)
	vim.keymap.set('n', 'q', close_picker, opt)
	vim.keymap.set('n', '<Esc>', close_picker, opt)
	vim.keymap.set('i', '<CR>', confirm_edit, opt)
	vim.keymap.set('i', '<Esc>', cancel_edit, opt)
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_set_current_win(win)
	vim.wo[win].number = false
	vim.wo[win].signcolumn = 'no'
	vim.wo[win].cursorline = true
	render_picker()
	vim.api.nvim_win_set_cursor(win, { 2, 0 })

	local chunks, err_chunks = {}, {}
	local job = vim.fn.jobstart({ 'gemini', '--list-sessions' }, {
		cwd = cwd,
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			chunks = data
		end,
		on_stderr = function(_, data)
			err_chunks = data
		end,
		on_exit = function(_, code)
			vim.schedule(function()
				if state.picker ~= p or p.cancelled then
					return
				end
				local found = code == 0 and parse_sessions(chunks) or {}
				if #found == 0 then
					-- Some versions print the list to stderr.
					found = parse_sessions(err_chunks)
				end
				p.loading = false
				if #found == 0 then
					p.load_error = code ~= 0
				else
					local newest = {}
					for i = #found, 1, -1 do
						table.insert(newest, found[i])
					end
					p.sessions = newest
				end
				render_picker()
			end)
		end,
	})
	if job <= 0 then
		p.loading = false
		p.load_error = true
		render_picker()
	end
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
		vim.keymap.set('n', 'A', spawn_resume, opt)
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
		close_strip()
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
			if ev.buf == state.board_buf then
				close_strip()
			end
			if state.picker and ev.buf == state.picker.buf then
				local p = state.picker
				state.picker = nil
				p.cancelled = true
				release_picker_window(p)
			end
			state.ticks[ev.buf] = nil
			state.last_active[ev.buf] = nil
			-- A session buffer gone by other means takes its
			-- compose buffer with it.
			local c = state.compose[ev.buf]
			if c then
				state.compose[ev.buf] = nil
				wipe_buffer(c)
			end
		end,
	})
end

-- Exposed for tests.
M._sessions = sessions
M._render = render
M._poll = poll
M._compose_for = compose_for
M._parse_sessions = parse_sessions
M._spawn_resume = spawn_resume
M._picker = function()
	return state.picker
end
M._strip_win = function()
	return state.strip_win
end
M._sync_strip = sync_strip

return M
