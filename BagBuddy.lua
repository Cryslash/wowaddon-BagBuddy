--  criar frame em lua
-- CreateFrame("Frame", "BagBuddy", UIParent)
-- BagBuddy:SetWidth(384)
-- BagBuddy:SetHeight(512)
-- BagBuddy:SetPoint("CENTER", UIParent, "CENTER")

--local _, BagBuddy = ...

function  BagBuddy_Onload(self)
    SetPortraitToTexture(self.portrait, "interface\\Icons\\INV_Misc_EngGizmos_30")

    --Create the item slots
    self.items = {}
    for idx = 1, 24 do
        local item = CreateFrame("Button", "BagBuddy_Item" .. idx, self, "BagBuddyItemTemplate")
        self.items[idx] = item
        if idx == 1 then
            item:SetPoint("TOPLEFT",40, -73)
        elseif idx == 7 or idx == 13 or idx == 19 then
            item:SetPoint("TOPLEFT", self.items[idx-6], "BOTTOMLEFT", 0, -7)
        else
            item:SetPoint("TOPLEFT", self.items[idx-1], "TOPRIGHT", 12, 0)
        end
    end

    --Create the filter buttons
    self.filters = {}
    for idx = 0, 5 do
        local button = CreateFrame("CheckButton", "BagBuddy_Filter"..idx, self, "BagBuddyFilterTemplate")
        SetItemButtonTexture(button,"Interface\\ICONS\\INV_Misc_Gem_Pearl_03")
        self.filters[idx] = button
        if idx == 0 then
            button:SetPoint("BOTTOMLEFT", 40, 200)
        else
            button:SetPoint("TOPLEFT", self.filters[idx-1], "TOPRIGHT", 12, 0)
        end

        local colortable = ITEM_QUALITY_COLORS[idx]
        button.icon:SetVertexColor(colortable["r"], colortable["g"], colortable["b"])
        button:SetChecked(false)
        button.quality = idx
        button.glow:Hide()
    end

    self.filters[-1] = self.filters[0]

    -- Assinalar scripts ao xml
    -- for idx, button in ipairs(self.items) do
    --     button:SetScript("OnEnter", BagBuddy_Button_OnEnter)
    --     button:SetScript("OnLeave", BagBuddy_Button_OnLeave)
    -- end
end

function MakeMovable(frame)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end

local function itemNameSort(a, b)
  return a.name < b.name
end

function BagBuddy_Update()
    local items = {}
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 0, C_Container.GetContainerNumSlots(bag) do
            --local texture, count, locked, quality, readable, lootable, link = C_Container.GetContainerItemInfo(bag,slot)
            local table = C_Container.GetContainerItemInfo(bag,slot)
            if table then
                local shown = true
                if BagBuddy.qualityFilter then
                   shown = shown and BagBuddy.filters[table["quality"]]:GetChecked()
                end
                if shown then
                   local itemNum = tonumber(table["hyperlink"]:match("|Hitem:(%d+):"))
                   if not items[itemNum] then
                      items[itemNum] = {
                      texture = table["iconFileID"],
                      count = table["stackCount"],
                      quality = table["quality"],
                      name = C_Item.GetItemInfo(table["hyperlink"]),
                      link = table["hyperlink"],}          
                    else
                      items[itemNum].count = items[itemNum].count + table["stackCount"]
                    end
                end
            end
        end
    end

    local sortTbl = {}
    for link, entry in pairs(items) do
        table.insert(sortTbl, entry)
    end
    table.sort(sortTbl, itemNameSort)

    for i = 1, 24 do
        local button = BagBuddy.items[i]
        local entry = sortTbl[i]

        if entry then
            button.link = entry.link
            button.icon:SetTexture(entry.texture)
            if entry.count > 1 then
                button.count:SetText(entry.count)
                button.count:Show()
            else
                button.count:Hide()
            end

            if entry.quality > 1 then
                --button.glow:SetVertexColor(C_Item.GetItemQualityColor(entry.quality))
                local colortable = ITEM_QUALITY_COLORS[entry.quality]
                button.glow:SetVertexColor(colortable["r"], colortable["g"], colortable["b"])
                button.glow:Show()
            else
                button.glow:Hide()
            end
            button:Show()
        else
            button.link = nil
            button:Hide()
        end
    end
end

--Eventos mouse hover para xml
function BagBuddy_Button_OnEnter(self, motion)
    if self.link then
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end
end

function BagBuddy_Button_OnLeave(self, motion)
    GameTooltip:Hide()
end

function BagBuddy_Filter_OnEnter(self, motion)
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    GameTooltip:SetText(_G["ITEM_QUALITY" .. self.quality .. "_DESC"])
    GameTooltip:Show()
end

function BagBuddy_Filter_OnLeave(self, motion)
    GameTooltip:Hide()
end

function BagBuddy_Filter_OnClick(self, button)
   BagBuddy.qualityFilter = false
   for idx= 0, 5 do
    local button = BagBuddy.filters[idx]
    if button:GetChecked() then
        BagBuddy.qualityFilter = true
    end
    BagBuddy_Update()
   end
end
