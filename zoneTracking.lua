local _, ns = ...

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("LOADING_SCREEN_DISABLED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("AREA_POIS_UPDATED")

local function UntrackAll()
	for i = 1, GetNumQuestLogEntries() do
		if IsQuestWatched(i) then
			RemoveQuestWatch(i)
		end
	end
end

local function UntrackNonplayerTracked()
	for i = 1, GetNumQuestLogEntries() do
		local _, _, _, _, _, _, _, questID = GetQuestLogTitle(i)
		if IsQuestWatched(i) and not OQ.userTrackedQuests[questID] then
			RemoveQuestWatch(i)
		end
	end
end

function TESTLOL()
	--local currMapID = C_Map.GetBestMapForUnit("player")
	local currMapID = C_QuestLog.GetMapForQuestPOIs()

	print("mapId: " .. currMapID)
	
	local data = C_QuestLog.GetQuestsOnMap(currMapID)
	for k,v in ipairs(data) do
		local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(GetQuestLogIndexByID(v.questID))

		local info = C_Map.GetMapInfoAtPosition(currMapID, v.x, v.y)
		ns.Util.Dump(info)

		if info.mapID == currMapID then
			AddQuestWatch(GetQuestLogIndexByID(v.questID))
		else
			print(title)
		end
	end
end

local function TrackByZone()
	if OQ.Options.ZoneTracking.Behaviour == "Fully Automatic" then
		UntrackAll()
	elseif OQ.Options.ZoneTracking.Behaviour == "Semi Automatic" then
		UntrackNonplayerTracked()
	end

	-- Take 3
	local currMapID = C_Map.GetBestMapForUnit("player")
	local data = C_QuestLog.GetQuestsOnMap(currMapID)
	for k,v in ipairs(data) do
		local info = C_Map.GetMapInfoAtPosition(currMapID, v.x, v.y)
		if info.mapID == currMapID then
			AddQuestWatch(GetQuestLogIndexByID(v.questID))
		end
	end

	-- Take 2
	-- local currMapID = C_Map.GetBestMapForUnit("player")
	-- local data = C_QuestLog.GetQuestsOnMap(currMapID)
	-- for k,v in ipairs(data) do
	-- 	local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(GetQuestLogIndexByID(v.questID))
	-- 	AddQuestWatch(GetQuestLogIndexByID(v.questID))
	-- end

 	-- Take 1

	-- local quests = {}
	-- for i = 1, GetNumQuestLogEntries() do
	-- 	local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
	-- 	if questID and questID ~= 0 then
	-- 		table.insert(quests, {
	-- 			title = title,
	-- 			questID = questID
	-- 			})
	-- 	end
	-- end

	-- if #quests > 0 then
	-- 	for i, questData in ipairs(quests) do
	-- 		local title = questData.title
	-- 		local questID = questData.questID

	-- 		local _,x,y = QuestPOIGetIconInfo(questID)
	-- 		if x and y then
	-- 			print("adding: " .. title)
	-- 			AddQuestWatch(GetQuestLogIndexByID(questID))
	-- 		else
	-- 			print("Not adding: " .. title)
	-- 		end
	-- 	end
	-- end

	-- OLD 

	-- local mapId = C_Map.GetBestMapForUnit("player")
	-- local currentMapName = C_Map.GetMapInfo(mapId).name
	-- local i = 1
	-- local watchQuest = false

	-- while GetQuestLogTitle(i) do
	-- 	local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)

	-- 	if isHeader then
	-- 		if title == currentMapName or (ns.ZoneNameSubstitutions[currentMapName] and tContains(ns.ZoneNameSubstitutions[currentMapName], title)) then
	-- 			watchQuest = true
	-- 		elseif watchQuest then
	-- 			break
	-- 		end
	-- 	elseif watchQuest then
	-- 		AddQuestWatch(GetQuestLogIndexByID(questID))
	-- 	end

	-- 	i = i + 1
	-- end

	--Consider the following for tracking world quests
	--[[

	for k, task in pairs(C_TaskQuest.GetQuestsForPlayerByMapID(GetCurrentMapAreaID())) do
		if task.inProgress then
			-- track active world quests
			local questID = task.questId
			local questName = C_TaskQuest.GetQuestInfoByQuestID(questID)
			if questName then
				print(k, questID, questName)
			end
		end
	end

	]]
end

function frame:QUEST_ACCEPTED()
	if OQ.Options.ZoneTracking.Behaviour ~= "Blizzard Default" then
		TrackByZone()
	end
end

function frame:ZONE_CHANGED_NEW_AREA()
	print("Zone Changed")
	if OQ.Options.ZoneTracking.Behaviour ~= "Blizzard Default" then
		TrackByZone()
	end
end

function frame:LOADING_SCREEN_DISABLED()
	if OQ.Options.ZoneTracking.Behaviour ~= "Blizzard Default" then
		TrackByZone()
	end
end

function frame:AREA_POIS_UPDATED()
	if OQ.Options.ZoneTracking.Behaviour ~= "Blizzard Default" then
		TrackByZone()
	end
end

function frame:PLAYER_LOGIN( ... )
	OQ.userTrackedQuests = OQ.userTrackedQuests or {}
	ns.Options:RegisterForOkay(function( ... )
		if OQ.Options.ZoneTracking.Behaviour == "Blizzard Default" then
			UntrackAll()

			-- Enable blizzard automatic quest tracking
			SetCVar("autoQuestWatch", "1")
		else
			-- Disable blizzard automatic quest tracking
			SetCVar("autoQuestWatch", "0")
			TrackByZone()
		end
	end)

	hooksecurefunc("QuestMapQuestOptions_TrackQuest", function(questID)
		if not OQ.userTrackedQuests[questID] and IsQuestWatched(GetQuestLogIndexByID(questID)) then
			OQ.userTrackedQuests[questID] = true
		else
			OQ.userTrackedQuests[questID] = nil	
		end
	end)
end
