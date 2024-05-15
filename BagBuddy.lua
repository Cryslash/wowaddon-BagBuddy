--  criar frame em lua
-- CreateFrame(“Frame“, “BagBuddy“, UIParent)
-- BagBuddy:SetWidth(384)
-- BagBuddy:SetHeight(512)
-- BagBuddy:SetPoint(“CENTER“, UIParent, “CENTER“)

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

end