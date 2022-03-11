local InfoPanel = table.Copy(vgui.GetControlTable("DPanel"))
local color_gray = Color(222, 222, 222)
local html_queue = {}

local function LegacyConfig(v)
    local dm = DermaMenu()

    for i, _ in pairs(v.config) do
        local x = menup.config.get(v.id, i)
        local cv = dm:AddOption(i)

        cv.DoClick = function()
            Derma_StringRequest("Change option", v.name .. "." .. i .. " = " .. tostring(x), tostring(x), function(txt)
                menup.config.set(v.id, i, tonumber(txt) == nil and txt or tonumber(txt))
            end)
        end

        if x == "true" or x == 1 or x == true then
            cv:SetIcon("icon16/tick.png")
        elseif x == "false" or x == 0 or x == false then
            cv:SetIcon("icon16/cross.png")
        else
            cv:SetIcon("icon16/pencil.png")
        end
    end

    dm:Open()
end

local cfpnls = {
    bool = function(id, key, data)
        local val = menup.config.get(id, key, isbool(data[3]) and data[3] or false)
        local root = vgui.Create("DPanel")
        local label = root:Add("DLabel")
        local cb = root:Add("DCheckBox")

        cb:Dock(RIGHT)
        cb:SetWide(15)
        cb:SetChecked(val)
        label:Dock(FILL)
        label:SetText(data[1])
        label:SetTextColor(Color(0, 0, 0))

        cb.OnChange = function(pnl, newval)
            hook.Run("UserConfigChange", id, key, newval, val)
            menup.config.set(id, key, newval)
        end

        return root
    end,
    int = function(id, key, data)
        local val = menup.config.get(id, key, isnumber(data[3]) and data[3] or 0)
        local root = vgui.Create("DPanel")
        local label = root:Add("DLabel")
        local wang = root:Add("DNumberWang")

        wang:Dock(RIGHT)
        wang:SetWide(96)
        wang:SetDecimals(0)
        wang:SetMin(-math.huge)
        wang:SetMax(math.huge)
        wang:SetValue(val)
        label:Dock(FILL)
        label:SetText(data[1])
        label:SetTextColor(Color(0, 0, 0))

        wang.OnValueChanged = function(pnl, newval)
            newval = math.Round(newval)

            if val ~= newval then
                wang:SetText(tostring(newval))
            end

            hook.Run("UserConfigChange", id, key, newval, val)
            menup.config.set(id, key, newval)
        end

        return root
    end,
    float = function(id, key, data)
        local val = menup.config.get(id, key, isnumber(data[3]) and data[3] or 0)
        local root = vgui.Create("DPanel")
        local label = root:Add("DLabel")
        local wang = root:Add("DNumberWang")

        wang:Dock(RIGHT)
        wang:SetWide(96)
        wang:SetMin(-math.huge)
        wang:SetMax(math.huge)
        wang:SetValue(val)
        label:Dock(FILL)
        label:SetText(data[1])
        label:SetTextColor(Color(0, 0, 0))

        wang.OnValueChanged = function(pnl, newval)
            hook.Run("UserConfigChange", id, key, newval, val)
            menup.config.set(id, key, newval)
        end

        return root
    end,
    range = function(id, key, data)
        local min, max, default = data[3][1], data[3][2], data[3][3]
        min = (min ~= nil and min or 0)
        max = (max ~= nil and max or 100)
        local val = menup.config.get(id, key, isnumber(default) and default or 0)
        local root = vgui.Create("DPanel")
        local slider = root:Add("DNumSlider")

        slider:Dock(FILL)
        slider:SetDecimals(3)
        slider:SetMinMax(min, max)
        slider:SetValue(val)
        slider:SetText(data[1])
        slider:SetDark(true)

        slider.OnValueChanged = function(pnl, newval)
            hook.Run("UserConfigChange", id, key, newval, val)
            menup.config.set(id, key, newval)
        end

        return root
    end,
    string = function(id, key, data)
        local val = menup.config.get(id, key, isstring(data[3]) and data[3] or "")
        local root = vgui.Create("DPanel")
        local label = root:Add("DLabel")
        local tbox = root:Add("DTextEntry")

        root:SetTall(48)
        tbox:Dock(BOTTOM)
        tbox:SetText(val)
        tbox:SetPlaceholderText(isstring(data[3]) and data[3])
        label:Dock(FILL)
        label:SetText(data[1])
        label:SetTextColor(Color(0, 0, 0))

        tbox.OnLoseFocus = function(pnl)
            local newval = pnl:GetText()
            hook.Run("UserConfigChange", id, key, newval, val)
            menup.config.set(id, key, newval)
        end

        return root
    end,
    select = function(id, key, data)
        local val = menup.config.get(id, key, 1)
        local root = vgui.Create("DPanel")
        local label = root:Add("DLabel")
        local combo = root:Add("DComboBox")

        root:SetTall(48)
        combo:Dock(BOTTOM)
        combo:SetSortItems(false)

        for k, txt in ipairs(data[3]) do
            if txt == "" then
                combo:AddSpacer()
            else
                combo:AddChoice(txt)
            end
        end

        combo:ChooseOptionID(val)
        label:Dock(FILL)
        label:SetText(data[1])
        label:SetTextColor(Color(0, 0, 0))

        combo.OnMenuOpened = function(pnl, dm)
            dm:GetChild(val):SetChecked(true)
        end

        combo.OnSelect = function(pnl, newval)
            hook.Run("UserConfigChange", id, key, newval, val)
            menup.config.set(id, key, newval)
            val = newval
        end

        return root
    end,
    color = function(id, key, data)
        local val = menup.config.get(id, key, istable(data[3]) and Color(data[3][1], data[3][2], data[3][3], data[3][4] or 255) or Color(255, 255, 255, 255))
        local root = vgui.Create("DPanel")
        local label = root:Add("DLabel")
        local preview = root:Add("DColorButton")

        preview:Dock(RIGHT)
        preview:SetWide(48)
        preview:SetColor(val, true)
        label:Dock(FILL)
        label:SetText(data[1])
        label:SetTextColor(Color(0, 0, 0))
        local picker

        preview.DoClick = function()
            if IsValid(picker) then
                picker:Remove()
            end

            picker = vgui.Create("DPanel")
            picker:SetSize(272, 296)
            local sx, sy = preview:LocalToScreen(24, 0)
            picker:SetPos(sx - 128, sy - 296)

            picker.Paint = function(s, w, h)
                picker:GetSkin().tex.Tab_Control(0, 0, w, h)
            end

            local cc = picker:Add("DColorMixer")
            cc:SetColor(val)

            -- why do i have to do this?
            timer.Simple(0, function()
                cc:SetColor(val)
            end)

            cc:SetPos(8, 8)
            cc:SetSize(256, 250)
            local detail = cc.WangsPanel:Add("DColorButton")
            detail:Dock(FILL)
            detail:DockMargin(0, 4, 0, 0)
            detail:SetColor(val)

            cc.ValueChanged = function(_, newval)
                detail:SetColor(Color(newval.r, newval.g, newval.b, newval.a))
            end

            local ok = picker:Add("DButton")
            ok:SetPos(94, 264)
            ok:SetSize(170, 24)
            ok:SetText("Save")
            ok:SetIcon("icon16/tick.png")

            ok.DoClick = function()
                local newval = cc:GetColor()
                preview:SetColor(newval, true)
                hook.Run("UserConfigChange", id, key, newval, val)
                menup.config.set(id, key, newval)
                picker:Remove()
            end

            local cancel = picker:Add("DButton")
            cancel:SetPos(8, 264)
            cancel:SetSize(86, 24)
            cancel:SetText("Cancel")
            cancel:SetIcon("icon16/cross.png")

            cancel.DoClick = function()
                picker:Remove()
            end

            picker:MakePopup()
        end

        return root
    end,
    keybind = function(id, key, data)
        if vgui.GetControlTable("DBinder") == nil then
            include("vgui/dbinder.lua") -- not included in menu realm by default
        end

        local val = menup.config.get(id, key, isnumber(data[3]) and data[3] or 0)
        local root = vgui.Create("DPanel")
        local label = root:Add("DLabel")
        local binder = root:Add("DBinder")

        binder:Dock(RIGHT)
        binder:SetWide(96)
        binder:SetValue(val)
        label:Dock(FILL)
        label:SetText(data[1])
        label:SetTextColor(Color(0, 0, 0))

        binder.OnChange = function(pnl, newval)
            hook.Run("UserConfigChange", id, key, newval, val)
            menup.config.set(id, key, newval)
        end

        return root
    end,
    file = function(id, key, data)
        if vgui.GetControlTable("DFileBrowser") == nil then
            include("vgui/dfilebrowser.lua") -- not included in menu realm by default
            include("vgui/dhorizontaldivider.lua")
        end

        -- base, match, default
        local val = menup.config.get(id, key, isstring(data[3][3]) and data[3][3] or nil)
        local base = isstring(data[3][1]) and data[3][1] or ""
        local match = isstring(data[3][2]) and data[3][2] or "*"
        local root = vgui.Create("DPanel")
        local label = root:Add("DLabel")
        local preview = root:Add("DButton")

        root:SetTall(48)
        preview:Dock(BOTTOM)
        preview:SetText(isstring(val) and val or "No file selected")
        label:Dock(FILL)
        label:SetText(data[1])
        label:SetTextColor(Color(0, 0, 0))
        local frame

        preview.DoClick = function()
            if IsValid(frame) then
                frame:Remove()
            end

            frame = vgui.Create("DFrame")
            frame:SetSize(512, 384)
            frame:Center()
            frame:SetTitle("Select file")
            frame:SetSizable(true)
            frame:SetScreenLock(true)
            frame:NoClipping(true)
            local bgcol = Color(0, 0, 0, 128)
            local message = "Double-click to select"

            frame.PaintOver = function(s, w, h)
                draw.RoundedBoxEx(16, 8, h, w - 16, 28, bgcol, false, false, true, true)
                surface.SetFont("Trebuchet24")
                local tw = surface.GetTextSize(message)
                surface.SetTextColor(color_white) -- where does this even come from lmao
                surface.SetTextPos(w / 2 - tw / 2, h)
                surface.DrawText(message)
            end

            local browser = frame:Add("DFileBrowser")
            browser:Dock(FILL)
            browser:SetOpen(true)
            browser:SetPath("GAME")
            browser:SetBaseFolder(base)
            browser:SetCurrentFolder(base)
            browser:SetSearch(match)

            browser.OnDoubleClick = function(_, newval)
                newval = newval:sub(#base + 2)
                preview:SetText(newval)
                hook.Run("UserConfigChange", id, key, newval, val)
                menup.config.set(id, key, newval)
                frame:Close()
            end

            frame:MakePopup()
        end

        return root
    end,
    stack = function(id, key, data)
        local val = menup.config.get(id, key, data[3])
        local root = vgui.Create("DPanel")
        local label = root:Add("DLabel")
        local combo = root:Add("DComboBox")

        root:SetTall(48)
        combo:Dock(BOTTOM)
        combo:SetSortItems(false)
        -- function combo.DropButton.GetExpanded(s)
        --     return combo:IsMenuOpen()
        -- end
        -- Derma_Hook(combo.DropButton, "Paint", "Paint", "ExpandButton")
        local enabled = 0
        local total = 0

        for k, v in SortedPairs(val) do
            combo:AddChoice(k)

            if v then
                enabled = enabled + 1
            end

            total = total + 1
        end

        combo:SetText(enabled .. "/" .. total .. " selected")
        label:Dock(FILL)
        label:SetText(data[1])
        label:SetTextColor(Color(0, 0, 0))

        combo.OnMenuOpened = function(_, pnl)
            enabled = 0
            pnl:SetDrawColumn(true)

            for i = 1, pnl:ChildCount() do
                local child = pnl:GetChild(i)
                local check = val[child:GetText()]

                if check then
                    child:SetChecked(true)
                    enabled = enabled + 1
                end
            end

            combo:SetText(enabled .. "/" .. total .. " selected")
        end

        combo.OnSelect = function(pnl, _, txt)
            local oldval = table.Copy(val)
            val[txt] = not val[txt]

            timer.Simple(0, function()
                combo:OpenMenu()
            end)

            hook.Run("UserConfigChange", id, key, val, oldval)
            menup.config.set(id, key, val)
        end

        return root
    end,
    sort = function(id, key, data)
        local val = menup.config.get(id, key, data[3])
        local root = vgui.Create("DPanel")
        local label = root:Add("DLabel")
        local combo = root:Add("DComboBox")

        root:SetTall(48)
        combo:Dock(BOTTOM)
        combo:SetSortItems(false)

        function combo.DropButton.GetExpanded(s)
            return combo:IsMenuOpen()
        end

        Derma_Hook(combo.DropButton, "Paint", "Paint", "ExpandButton")
        label:Dock(FILL)
        label:SetText(data[1])
        label:SetTextColor(Color(0, 0, 0))
        combo:SetText(table.concat(val, ", "))

        combo.DoClick = function(_, force)
            if IsValid(combo.Menu) then
                combo.Menu:Remove()
                if not force then return end
            end

            val = menup.config.get(id, key, data[3])
            local dm = DermaMenu(false, combo)
            combo.Menu = dm
            local ll = dm:Add("DListLayout")
            ll:MakeDroppable("menup." .. id .. "." .. key)
            ll.children = {}
            dm:AddPanel(ll)

            for k, v in ipairs(val) do
                local pan = ll:Add("DPanel")
                local txt = pan:Add("DLabel")
                pan.pos = k
                pan.val = v
                ll.children[k] = pan
                pan.GetChecked = function() end

                pan.Paint = function(_, w, h)
                    draw.RoundedBox(0, 1, 0, 22, 22, color_gray)
                    draw.RoundedBox(0, 22, 0, w - 23, 22, (pan.pos % 2 == 0) and color_gray or color_white)
                    derma.SkinHook("Paint", "MenuOption", pan, w, h)

                    if pan:IsHovered() and not dragndrop.IsDragging() then
                        pan:GetSkin().tex.Input.Slider.V.Normal(3, 3, 15, 16)
                    else
                        surface.SetFont("DermaDefaultBold")
                        surface.SetTextColor(Color(0, 0, 0))
                        surface.SetTextPos(4, 4)
                        surface.DrawText(pan.pos .. ":")
                    end
                end

                pan:Dock(TOP)
                pan:SetTall(22)
                txt:Dock(RIGHT)
                txt:SetWide(combo:GetWide() - 28)
                txt:SetDark(true)
                txt:SetText(v)
            end

            ll.OnModified = function(_, refresh)
                timer.Simple(0, function()
                    if not IsValid(ll) then return end
                    local newval = {}

                    for k, v in ipairs(ll.children) do
                        if not IsValid(v) then continue end
                        local pan = v
                        local pos = pan:GetY() / 22 + 1
                        pan.pos = pos
                        newval[pos] = pan.val
                    end

                    combo:SetText(table.concat(newval, ", "))
                    hook.Run("UserConfigChange", id, key, newval, val)
                    menup.config.set(id, key, newval)

                    if refresh then
                        combo:DoClick(true):MakePopup()
                    end
                end)
            end

            local x, y = combo:LocalToScreen(0, combo:GetTall())
            dm:SetMinimumWidth(combo:GetWide())
            dm:Open(x, y, false, combo)
        end

        return root
    end,
    -- this was so painful
    list = function(id, key, data)
        local val = menup.config.get(id, key, data[3])
        local root = vgui.Create("DPanel")
        local label = root:Add("DLabel")
        local combo = root:Add("DComboBox")

        root:SetTall(48)
        combo:Dock(BOTTOM)
        combo:SetSortItems(false)

        function combo.DropButton.GetExpanded(s)
            return combo:IsMenuOpen()
        end

        Derma_Hook(combo.DropButton, "Paint", "Paint", "ExpandButton")
        label:Dock(FILL)
        label:SetText(data[1])
        label:SetTextColor(Color(0, 0, 0))
        combo:SetText(table.concat(val, ", "))

        combo.DoClick = function(_, force)
            if IsValid(combo.Menu) then
                combo.Menu:Remove()
                if not force then return end
            end

            val = menup.config.get(id, key, data[3])
            local dm = DermaMenu(false, combo)
            combo.Menu = dm
            local add = dm:Add("DButton")
            local ll = dm:Add("DListLayout")
            add:Dock(TOP)
            add:SetTall(22)
            add:SetText("Add")
            add:SetIcon("icon16/add.png")

            add.DoClick = function()
                local newval = table.Copy(val)
                table.insert(newval, 1, "")
                menup.config.set(id, key, newval)
                hook.Run("UserConfigChange", id, key, newval, val)
                local newdm = combo:DoClick(true)
                newdm.first:RequestFocus()
            end

            ll:MakeDroppable("menup." .. id .. "." .. key)
            ll.children = {}
            dm:AddPanel(ll)

            for k, v in ipairs(val) do
                local pan = ll:Add("DPanel")
                local ep = pan:Add("EditablePanel")
                local del = pan:Add("DButton")
                local txt = ep:Add("DTextEntry")

                if k == 1 then
                    dm.first = txt
                end

                pan.pos = k
                pan.val = v
                ll.children[k] = pan
                pan.GetChecked = function() end

                pan.Paint = function(_, w, h)
                    draw.RoundedBox(0, 1, 0, 22, h, color_gray)
                    draw.RoundedBox(0, 22, 0, w - 23, h, (pan.pos % 2 == 0) and color_gray or color_white)

                    if (pan:IsHovered() or pan:IsChildHovered() or txt:IsEditing()) and not dragndrop.IsDragging() then
                        pan:GetSkin().tex.Input.Slider.V.Hover(3, 3, 15, 16)
                        txt:SetPaintBackground(true)
                        del:SetVisible(true)
                    else
                        surface.SetFont("DermaDefaultBold")
                        surface.SetTextColor(Color(0, 0, 0))
                        surface.SetTextPos(4, 4)
                        surface.DrawText(pan.pos .. ":")
                        txt:SetPaintBackground(false)
                        del:SetVisible(false)
                    end
                end

                del.DoClick = function()
                    pan:Remove()
                    ll:OnModified()
                end

                txt.OnGetFocus = function()
                    txt:MakePopup()
                    txt:SetDrawOnTop(true)
                    txt:SetPos(pan:LocalToScreen(22, 0))
                end

                txt.OnLoseFocus = function()
                    -- focus isnt automatically removed and the panel bugs out
                    -- this is the nuclear option :)
                    pan.val = txt:GetValue()
                    ll:OnModified(true)
                end

                txt.OnKeyCode = function(_, kc)
                    if kc == KEY_ENTER or kc == KEY_TAB then
                        txt:OnLoseFocus()
                    end
                end

                pan:Dock(TOP)
                pan:SetTall(22)
                del:SetPos(combo:GetWide() - 22, 0)
                del:SetSize(22, 22)
                del:SetText("")
                del:SetIcon("icon16/cancel.png")
                del:Hide()
                ep:SetPos(22, 0)
                ep:SetSize(combo:GetWide() - 43, 22)
                ep:SetPaintBackgroundEnabled(false)
                txt:SetPos(0, 0)
                txt:SetSize(ep:GetSize())
                txt:SetText(pan.val)
                txt:SetPlaceholderText("(Empty)")
                txt:SetPaintBackground(false)
                txt:SetEnterAllowed(true)
                txt:SetMultiline(false)
                pan:InvalidateLayout(false)
            end

            ll.OnModified = function(_, refresh)
                timer.Simple(0, function()
                    if not IsValid(ll) then return end
                    local newval = {}

                    for k, v in ipairs(ll.children) do
                        if not IsValid(v) then continue end
                        local pan = v
                        local pos = pan:GetY() / 22 + 1
                        pan.pos = pos
                        newval[pos] = pan.val
                    end

                    combo:SetText(table.concat(newval, ", "))
                    hook.Run("UserConfigChange", id, key, newval, val)
                    menup.config.set(id, key, newval)

                    if refresh then
                        combo:DoClick(true):MakePopup()
                    end
                end)
            end

            local x, y = combo:LocalToScreen(0, combo:GetTall())
            dm:SetMinimumWidth(combo:GetWide())
            dm:Open(x, y, false, combo)

            return dm
        end

        return root
    end,
}

-- this was even more painful
function InfoPanel:Init()
    self:SetTall(512)
    self:SetPaintBackground(false)
    local controls = self:Add("DPanel")
    controls:SetPaintBackground(false)
    controls:Dock(TOP)
    controls:SetTall(36)
    local toggle = controls:Add("DButton")
    local alt = controls:Add("DButton")
    local md = self:Add("DPanel")
    local cp = self:Add("DScrollPanel")
    md:SetPos(0, 32)
    md:SetTall(512)
    md:SetPaintBackground(false)
    cp:SetPos(self:GetWide(), 32)
    cp:SetTall(512)
    self.controls = controls
    self.toggle = toggle
    self.alt = alt
    self.md = md
    self.cp = cp
    self.scroll = 0
    self.target = 0
end

function InfoPanel:Think()
    local w = self.controls:GetWide()
    local h = self:GetParent():GetParent():GetParent():GetTall() - 56 -- info collapse list sheet frame
    self.scroll = Lerp(FrameTime() * 10, self.scroll, self.target)
    local s = self.scroll
    self.toggle:SetWide(w / 2)
    self.alt:SetWide(w / 2)
    self.md:SetSize(w, h)
    self.cp:SetSize(w, h)
    self.alt:SetPos(w / 2, 0)
    self.md:SetPos(-w * s, 32)
    self.cp:SetPos((1 - s) * w, 32)
end

function InfoPanel:SetEnabled(state)
    self.target = 0
    local manifest = self.manifest
    menup.control[state and "enable" or "disable"](manifest.id)
    self:GetParent().toggle:SetChecked(state)
    self:Load(manifest)
end

function InfoPanel:BuildConfig(manifest)
    self.cp:Clear()

    -- name type param desc
    for k, v in SortedPairs(manifest.config) do
        if isfunction(cfpnls[v[2]]) then
            local pnl = cfpnls[v[2]](manifest.id, k, v)
            self.cp:AddItem(pnl)
            pnl:Dock(TOP)
            pnl:DockPadding(4, 4, 4, 4)
            pnl:DockMargin(0, 2, 0, 2)
            if isstring(v[4]) then
                pnl:SetTooltip(v[4])
                pnl:SetTooltipDelay(0) -- https://github.com/Facepunch/garrysmod/pull/1875 please
            end
        else
            print(manifest.id .. " has unknown config type \"" .. v[2] .. "\" for key \"" .. k .. "\"!")
        end
    end

    local apply = self.cp:Add("DButton")
    apply:Dock(TOP)
    apply:DockPadding(4, 4, 4, 4)
    apply:DockMargin(32, 8, 32, 0)
    apply:SetTall(32)
    apply:SetText("Apply settings")
    apply:SetIcon("icon16/disk.png")

    apply.DoClick = function()
        hook.Run("ConfigApply", manifest.id)
    end
end

function InfoPanel:Load(manifest)
    self.manifest = manifest
    local info = string.format([[
## %s
%s  
## 
*Author* : %s  
*Version* : %s  
*ID* : `%s`  
*File* : `%s`  
]], manifest.name, manifest.description, manifest.author, manifest.version, manifest.id, manifest.file)

    if manifest.source then
        info = info .. string.format("*Source* : [%s](%s)  \n", manifest.source:match("^https?://([^/]+)"), manifest.source)
    end

    if manifest.initalization then
        info = info .. string.format("*Initalization* : %s ms  \n", tostring(manifest.initalization))
    end

    -- self.md:SetMarkdown(info)
    table.insert(html_queue, {self.md, info}) -- hopefully this fixes the crashing issue

    if manifest.enabled then
        self.toggle:SetText("Disable")
        self.toggle:SetIcon("icon16/delete.png")
        self.alt:SetText("Config")
        self.alt:SetIcon("icon16/cog.png")
        self.alt:SetEnabled(not table.IsEmpty(manifest.config))
    else
        self.toggle:SetText("Enable")
        self.toggle:SetIcon("icon16/add.png")
        self.alt:SetText("Reset")
        self.alt:SetIcon("icon16/control_repeat.png")
        self.alt:SetEnabled(true)
    end

    self.toggle.DoClick = function(pnl)
        self:SetEnabled(not manifest.enabled)
    end

    self.alt.DoClick = function(pnl)
        -- goto config
        if manifest.enabled and self.target == 0 then
            self:BuildConfig(manifest)
            self.target = 1
            self.alt:SetText("Description")
            self.alt:SetIcon("icon16/text_dropcaps.png")
        elseif manifest.enabled and self.target == 1 then
            -- goto description
            self.target = 0
            self.alt:SetText("Config")
            self.alt:SetIcon("icon16/cog.png")
        else -- reset
            Derma_Query("Are you sure you want to reset this plugins config & store?", "Confirmation", "Yes", function()
                hook.Run("PluginReset", manifest)
                menup.db.del("data_" .. manifest.id)
            end, "No")
        end
    end
end

local PANEL = {}

function PANEL:Init()
    local new, legacy = {}, {}
    local lcollapse
    self.plugins = {}
    self:SetPaintBackground(false)

    for _, v in SortedPairsByMemberValue(menup.plugins, "name") do
        if v.legacy then
            table.insert(legacy, v)
        else
            table.insert(new, v)
        end
    end

    for _, v in ipairs(new) do
        local collapse = self:Add("     " .. v.name)
        local toggle = collapse.Header:Add("DCheckBox")
        toggle:SetPos(2, 2)
        toggle:SetChecked(v.enabled)
        local info = vgui.CreateFromTable(InfoPanel, collapse)
        collapse:SetContents(info)
        collapse:SetExpanded(false)

        function collapse.OnToggle(me, state)
            if not state then return end
            -- info.target = 0

            for _, c in pairs(self:GetChildren()[1]:GetChildren()) do
                if c ~= me then
                    c:DoExpansion(false)
                end
            end

            timer.Simple(me:GetAnimTime(), function()
                self:ScrollToChild(collapse)
            end)
        end

        function toggle:OnChange(state)
            info:SetEnabled(state)
        end

        info:Load(v)
        collapse.toggle = toggle
        collapse.info = info
        self.plugins[v.id] = collapse
    end

    if not table.IsEmpty(legacy) then
        lcollapse = self:Add("Legacy plugins")
        lcollapse:SetExpanded(false)

        lcollapse.OnToggle = function(me, state)
            if not state then return end

            for _, c in pairs(self:GetChildren()[1]:GetChildren()) do
                if c ~= me then
                    c:DoExpansion(false)
                end
            end

            timer.Simple(me:GetAnimTime(), function()
                self:ScrollToChild(lcollapse)
            end)
        end

        for _, v in ipairs(legacy) do
            local btn = lcollapse:Add(v.name)
            btn:SetTall(22)
            btn:SetEnabled(false)
            btn:SetCursor("arrow")

            btn.Paint = function(pnl, w, h)
                draw.NoTexture()
                surface.SetDrawColor(255, 255, 255)
                surface.DrawRect(0, 0, w, h)
                derma.SkinHook("Paint", "CategoryButton", pnl, w, h)
            end

            local alt = btn:Add("DButton")
            alt:Dock(RIGHT)
            alt:SetWide(22)
            alt:SetText("")
            alt:SetIcon("icon16/cog.png")
            local toggle = btn:Add("DButton")
            toggle:Dock(RIGHT)
            toggle:SetWide(22)
            toggle:SetText("")

            alt.DoClick = function()
                LegacyConfig(v)
            end

            toggle.DoClick = function()
                local state = not v.enabled
                menup.control[state and "enable" or "disable"](v.id)
                alt:SetEnabled(v.enabled and not table.IsEmpty(v.config))
                toggle:SetIcon(v.enabled and "icon16/lightbulb.png" or "icon16/lightbulb_off.png")
            end

            alt:SetEnabled(v.enabled and not table.IsEmpty(v.config))
            toggle:SetIcon(v.enabled and "icon16/lightbulb.png" or "icon16/lightbulb_off.png")
        end
    end
end

function PANEL:Paint()
end

hook.Add("DrawOverlay", "MPR_HTML", function()
    if #html_queue > 0 then
        local data = table.remove(html_queue, 1)
        local md = data[1]:Add("MarkdownPanel")
        md:SetMarkdown(data[2])
        md:Dock(FILL)
    end
end)

vgui.Register("PluginsPanel", PANEL, "DCategoryList")