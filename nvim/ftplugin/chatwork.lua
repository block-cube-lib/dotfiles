vim.opt_local.cindent = false

local function show_chatwork_emojis()
	local patterns = {
		[":)"] = "🙂",
		[":("] = "😔",
		[":D"] = "😆",
		["8-)"] = "😎",
		[":o"] = "😲",
		[";)"] = "😉",
		[";("] = "😢",
		["(sweat)"] = "😥",
		[":|"] = "😐",
		[":*"] = "😘",
		[":p"] = "😛",
		["(blush)"] = "☺️",
		[":^)"] = "🤨",
		["|-)"] = "😴",
		["(inlove)"] = "🥰",
		["]:)"] = "😀",
		["(talk)"] = "🗣",
		["(yawn)"] = "🥱",
		["(puke)"] = "🤮",
		["(emo)"] = "🧑",
		["8-|"] = "🤓",
		[":#)"] = "😏",
		["(nod)"] = "🙂‍↕",
		["(shake)"] = "🙅",
		["(^^;)"] = "😅",
		["(whew)"] = "💦",
		["(clap)"] = "👏",
		["(bow)"] = "🙇",
		["(roger)"] = "🙆",
		["(flex)"] = "💪",
		["(dance)"] = "🕺",
		[":/)"] = "😝",
		["(gogo)"] = "✊",
		["(think)"] = "🤔",
		["(please)"] = "🙏",
		["(quick)"] = "💨",
		["(anger)"] = "😠",
		["(devil)"] = "😈",
		["(lightbulb)"] = "💡",
		["(*)"] = "⭐",
		["(h)"] = "💗",
		["(F)"] = "🌸",
		["(cracker)"] = "🎉",
		["(eat)"] = "🍽️",
		["(^)"] = "🎂",
		["(coffee)"] = "☕",
		["(beer)"] = "🍺",
		["(handshake)"] = "🤝",
		["(y)"] = "👍",
	}

	local ns_id = vim.api.nvim_create_namespace("chatwork_emojis")
	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	-- delete old extmarks
	vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

	for line_nr, line_text in ipairs(lines) do
		local start_col = 0
		for pattern, replacement in pairs(patterns) do
			local match_start = string.find(line_text, pattern, start_col + 1, true)
			if match_start then
				local end_col = match_start + #pattern - 1
				vim.api.nvim_buf_set_extmark(
					buf,
					ns_id,
					line_nr - 1,
					match_start,
					{
						virt_text = { { replacement, 'Comment' }, { pattern, 'Comment' } },
						--virt_text_pos = 'overlay',
						end_col = end_col,
					}
				)
				start_col = end_col
			end
		end
	end
end

-- Create a buffer-local augroup to avoid duplication
local group = vim.api.nvim_create_augroup("chatwork_emojis_" .. vim.api.nvim_get_current_buf(), { clear = true })

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufEnter" }, {
	group = group,
	buffer = 0,
	callback = show_chatwork_emojis,
})

-- Run once on initial load
show_chatwork_emojis()
