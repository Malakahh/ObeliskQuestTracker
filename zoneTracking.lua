local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("LOADING_SCREEN_DISABLED")

local function UntrackAll()
	for i = 1, GetNumQuestLogEntries() do
		if IsQuestWatched(i) then
			RemoveQuestWatch(i)
		end
	end
end

local function TrackByZone()
	UntrackAll()

	--local currentMapName = GetZoneText()
	SetMapToCurrentZone()
	local currentMapName = GetMapNameByID(GetCurrentMapAreaID())

	local i = 1
	local watchQuest = false

	while GetQuestLogTitle(i) do
		local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)

		if isHeader then
			if title == currentMapName then
				watchQuest = true
			elseif watchQuest then
				break
			end
		elseif watchQuest then
			AddQuestWatch(GetQuestLogIndexByID(questID))
		end

		i = i + 1
	end
end

function frame:QUEST_ACCEPTED()
	TrackByZone()
end

function frame:ZONE_CHANGED_NEW_AREA()
	TrackByZone()
end

function frame:LOADING_SCREEN_DISABLED()
	TrackByZone()
end

