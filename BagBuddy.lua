--  criar frame em lua
-- CreateFrame("Frame", "BagBuddy", UIParent)
-- BagBuddy:SetWidth(384)
-- BagBuddy:SetHeight(512)
-- BagBuddy:SetPoint("CENTER", UIParent, "CENTER")

--local _, BagBuddy = ...

SLASH_BAGBUDDY1 = "/bb"
SLASH_BAGBUDDY2 = "/bagbuddy"
SlashCmdList["BAGBUDDY"] = function(msg, editbox)
    BagBuddy.input:SetText(msg)
    ShowUIPanel(BagBuddy)
end

function  BagBuddy_Onload(self)
    UIPanelWindows["BagBuddy"] = {
        area = "left",
        pushable = 1,
        whileDead = 1,
    }

    SetPortraitToTexture(self.portrait, "interface\\Icons\\INV_Misc_EngGizmos_30")

    --Create the item slots
    self.items = {}
    for idx = 1, 24 do
        local item = CreateFrame("Button", "BagBuddy_Item" .. idx, self, "BagBuddyItemTemplate")
        item:RegisterForClicks("RightButtonUp")
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
    -- Initialize to show the first page
    self.page = 1
    -- Store item counts for each bag
    self.bagCounts = {}

    self:RegisterEvent("ADDON_LOADED")

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

local function itemTimeNameSort(a,b)
    -- If the two items were looted at the same time
        
    local aTime = BagBuddy_ItemTimes[a.num]
    local bTime = BagBuddy_ItemTimes[b.num]
    
    if aTime == bTime then
        return a.name < b.name
    else
        return aTime >= bTime
    end
end

function BagBuddy_Update()
    local items = {}
    local nameFilter = BagBuddy.input:GetText():lower()
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 0, C_Container.GetContainerNumSlots(bag) do
            --local texture, count, locked, quality, readable, lootable, link = C_Container.GetContainerItemInfo(bag,slot)
            local table = C_Container.GetContainerItemInfo(bag,slot)
            if table then
                local shown = true
                if BagBuddy.qualityFilter then
                   shown = shown and BagBuddy.filters[table["quality"]]:GetChecked()
                end
                if #nameFilter > 0 then
                    local lowerName = C_Item.GetItemInfo(table["hyperlink"]):lower()
                    shown = shown and string.find(lowerName, nameFilter, 1, true)
                end
                if shown then
                   local itemNum = tonumber(table["hyperlink"]:match("|Hitem:(%d+):"))
                   if not items[itemNum] then
                    if itemNum then
                      items[itemNum] = {
                      texture = table["iconFileID"],
                      count = table["stackCount"],
                      quality = table["quality"],
                      name = C_Item.GetItemInfo(table["hyperlink"]),
                      link = table["hyperlink"],
                      num = itemNum,
                      }
                    end
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
    table.sort(sortTbl, itemTimeNameSort)

    local max = BagBuddy.page * 24
    local min = max - 23
    
    for idx = min, max do
        local button = BagBuddy.items[idx - min + 1]
        local entry = sortTbl[idx]

        if entry then
            button:SetAttribute("item2", entry.name)
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

    -- navigators buttons block
    if min > 1 then
        BagBuddy.prev:Enable()
    else
        BagBuddy.prev:Disable()
    end
    
    if max < #sortTbl then
        BagBuddy.next:Enable()
    else
        BagBuddy.next:Disable()
    end
    
    --Update the status text
    if #sortTbl > 24 then
        local max = math.min(max, #sortTbl)
        local msg = string.format("Mostrando items %d - %d de %d", min, max, #sortTbl)
        BagBuddy.status:SetText(msg)
    else
        BagBuddy.status:SetText("Encontrado ".. #sortTbl .. " itens")
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
-- Onclick event for filter button
function BagBuddy_Filter_OnClick(self, button)
   BagBuddy.qualityFilter = false
   for idx= 0, 5 do
    local button = BagBuddy.filters[idx]
    if button:GetChecked() then
        BagBuddy.qualityFilter = true
    end
    BagBuddy.page = 1
    BagBuddy_Update()
   end
end

function BagBuddy_NextPage(self)
    BagBuddy.page = BagBuddy.page + 1
    BagBuddy_Update(BagBuddy)
end

function BagBuddy_PrevPage(self)
    BagBuddy.page = BagBuddy.page - 1
    BagBuddy_Update(BagBuddy)
end

function BagBuddy_ScanBag(bag, initial)
    if not BagBuddy.bagCounts[bag] then
        BagBuddy.bagCounts[bag] = {}
    end

    local itemCounts = {}
    for slot = 0, C_Container.GetContainerNumSlots(bag) do
        local table = C_Container.GetContainerItemInfo(bag, slot)
        if table then
            local itemId = tonumber(table["hyperlink"]:match("|Hitem:(%d+):"))
            if itemId then
                if not itemCounts[itemId] then
                   itemCounts[itemId] = table["stackCount"]
                else
                   itemCounts[itemId] = itemCounts[itemId] + table["stackCount"]
                end
            end
        end
    end
    if initial then
        for itemId, count in pairs(itemCounts) do
            BagBuddy_ItemTimes[itemId] = BagBuddy_ItemTimes[itemId] or time()
        end
    else
        for itemId, count in pairs(itemCounts) do
            local oldCount = BagBuddy.bagCounts[bag][itemId] or 0
            if count > oldCount then
                BagBuddy_ItemTimes[itemId] = time()
            end
        end
    end
    BagBuddy.bagCounts[bag] = itemCounts
end

function BagBuddy_OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == "BagBuddy" then
        if not BagBuddy_ItemTimes then
            BagBuddy_ItemTimes = {}            
        end
        for bag = 0, NUM_BAG_SLOTS do
            -- Use the optional flag to skip updating times
            BagBuddy_ScanBag(bag, true)
        end
        self:UnregisterEvent("ADDON_LOADED")
        self:RegisterEvent("BAG_UPDATE")
    elseif event == "BAG_UPDATE" then
        local bag = ...do
            if bag >= 0 then
                BagBuddy_ScanBag(bag)
                if BagBuddy:IsVisible() then
                    BagBuddy_Update()
                end
            end
        end
    end
end
