-- Helper to toggle a window
local function toggleWindow(win, launchFunc)
    if win then
        if win == hs.window.focusedWindow() then
            win:application():hide()
        else
            win:focus()
        end
    else
        launchFunc()
    end
end

-- Function to find GhostText window (by title only for reliability)
local function findGhostWindow()
    for _, win in ipairs(hs.window.allWindows()) do
        local title = win:title() or ""
        if title:lower():find("ghosttext") then
            return win
        end
    end
    return nil
end

-- Function to find main WezTerm window
local function findMainWindow()
    for _, win in ipairs(hs.window.allWindows()) do
        local app = win:application()
        local bundleID = app and app:bundleID() or ""
        local title = win:title() or ""
        if bundleID == "com.github.wez.wezterm" and not title:lower():find("ghosttext") then
            return win
        end
    end
    return nil
end

-- bind hotkey: alt(meta) + space
-- toggle main WezTerm (exclude GhostText)
hs.hotkey.bind({ "alt" }, "space", function()
    local win = findMainWindow()
    toggleWindow(win, function()
        hs.application.launchOrFocus("WezTerm")
    end)
end)

-- bind hotkey: alt(meta) + k
-- launch/toggle WezTerm with nvim for GhostText
hs.hotkey.bind({ "alt" }, "k", function()
    local win = findGhostWindow()
    toggleWindow(win, function()
        -- Launch nvim through a login shell to ensure environment variables are loaded
        local nvim_command = "/opt/homebrew/bin/nvim -c 'set title titlestring=GhostText-Nvim'"
        local args = { 
            "start", 
            "--", 
            "/bin/zsh", "-l", "-c", nvim_command 
        }
        hs.task.new("/opt/homebrew/bin/wezterm", nil, args):start()
    end)
end)

-- bind hotkey: alt(meta) + c
-- toggle VS Code
hs.hotkey.bind({ "alt" }, "c", function()
    local app = hs.application.find("Code")
    if not app then
        hs.application.launchOrFocus("Code")
    elseif app:isFrontmost() then
        app:hide()
    else
        app:activate()
    end
end)

-- Move the focused window to the mouse position, centered
hs.hotkey.bind({"alt", "ctrl"}, "M", function()
    local win = hs.window.focusedWindow()
    if not win then return end

    local mousePos = hs.mouse.absolutePosition()
    local frame = win:frame()

    win:setTopLeft({
        x = mousePos.x - (frame.w / 2),
        y = mousePos.y - (frame.h / 2)
    })
end)

-- Machine-specific settings live in init.local.lua
-- (same directory, git-ignored) and are loaded when present.
local local_init = hs.configdir .. "/init.local.lua"
if hs.fs.attributes(local_init) then
    dofile(local_init)
end
