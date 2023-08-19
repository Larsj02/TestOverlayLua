---@diagnostic disable: deprecated
local specToClass = {
    [250] = "DEATH_KNIGHT", -- Blood
    [251] = "DEATH_KNIGHT", -- Frost
    [252] = "DEATH_KNIGHT", -- Unholy
    [1455] = "DEATH_KNIGHT", -- Initial

    [577] = "DEMON_HUNTER", -- Havoc
    [581] = "DEMON_HUNTER", -- Vengeance
    [1456] = "DEMON_HUNTER", -- Initial

    [102] = "DRUID", -- Balance
    [103] = "DRUID", -- Feral
    [104] = "DRUID", -- Guardian
    [105] = "DRUID", -- Restoration
    [1447] = "DRUID", -- Initial

    [1467] = "EVOKER", -- Devastation
    [1468] = "EVOKER", -- Preservation
    [1473] = "EVOKER", -- Augmentation
    [1465] = "EVOKER", -- Initial

    [253] = "HUNTER", -- Beast Mastery
    [254] = "HUNTER", -- Marksmanship
    [255] = "HUNTER", -- Survival
    [1448] = "HUNTER", -- Initial

    [62] = "MAGE", -- Arcane
    [63] = "MAGE", -- Fire
    [64] = "MAGE", -- Frost
    [1449] = "MAGE", -- Initial

    [268] = "MONK", -- Brewmaster
    [270] = "MONK", -- Mistweaver
    [269] = "MONK", -- Windwalker
    [1450] = "MONK", -- Initial

    [65] = "PALADIN", -- Holy
    [66] = "PALADIN", -- Protection
    [70] = "PALADIN", -- Retribution
    [1451] = "PALADIN", -- Initial

    [256] = "PRIEST", -- Discipline
    [257] = "PRIEST", -- Holy
    [258] = "PRIEST", -- Shadow
    [1452] = "PRIEST", -- Initial

    [259] = "ROGUE", -- Assassination
    [260] = "ROGUE", -- Outlaw
    [261] = "ROGUE", -- Subtlety
    [1453] = "ROGUE", -- Initial

    [262] = "SHAMAN", -- Elemental
    [263] = "SHAMAN", -- Enhancement
    [264] = "SHAMAN", -- Restoration
    [1444] = "SHAMAN", -- Initial

    [265] = "WARLOCK", -- Affliction
    [266] = "WARLOCK", -- Demonology
    [267] = "WARLOCK", -- Destruction
    [1454] = "WARLOCK", -- Initial

    [71] = "WARRIOR", -- Arms
    [72] = "WARRIOR", -- Fury
    [73] = "WARRIOR", -- Protection
    [1446] = "WARRIOR", -- Initial
}

local classColors = {
    ["DEATH_KNIGHT"] = "#C41E3A",
    ["DEMON_HUNTER"] = "#A330C9",
    ["DRUID"] = "#FF7C0A",
    ["EVOKER"] = "#33937F",
    ["HUNTER"] = "#AAD372",
    ["MAGE"] = "#3FC7EB",
    ["MONK"] = "#00FF98",
    ["PALADIN"] = "#F48CBA",
    ["PRIEST"] = "#FFFFFF",
    ["ROGUE"] = "#FFF468",
    ["SHAMAN"] = "#0070DD",
    ["WARLOCK"] = "#8788EE",
    ["WARRIOR"] = "#C69B6D",
}

local advancedEvents = {
    ["DAMAGE_SPLIT"] = 13,
    ["SPELL_CAST_SUCCESS"] = 13,
    ["SPELL_DAMAGE"] = 13,
    ["SPELL_ENERGIZE"] = 13,
    ["SPELL_HEAL"] = 13,
    ["SPELL_PERIODIC_DAMAGE"] = 13,
    ["SPELL_PERIODIC_ENERGIZE"] = 13,
    ["SPELL_PERIODIC_HEAL"] = 13,
    ["SWING_DAMAGE"] = 10,
    ["SWING_DAMAGE_LANDED"] = 10,
}

DataProcess = {
    fileDir = "C:\\Program Files (x86)\\World of Warcraft\\_retail_\\Logs",
    logFile = nil,
    lastFileSize = 0,
    activeAuras = {},
    groupData = {},
    encounterData = {current = {}, last = {}}
}

function DataProcess:New(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    obj:RefreshFilePath()
    return obj
end

function DataProcess:ColorString(text, hexColor)
    local escapeCode = string.format("\27[38;2;%d;%d;%dm",
        tonumber(hexColor:sub(2, 3), 16),
        tonumber(hexColor:sub(4, 5), 16),
        tonumber(hexColor:sub(6, 7), 16))
    local resetCode = "\27[0m"
    return escapeCode .. text .. resetCode
end

function DataProcess:FormatMilliseconds(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    local millisecondsPart = milliseconds % 1000

    return string.format("%02d:%02d.%03d", minutes, seconds, millisecondsPart)
end


function DataProcess:RefreshFilePath()
    local lfs = require "lfs"
    local lastModificationTime = 0
    for file in lfs.dir(self.fileDir) do
        local fullPath = string.format("%s\\%s",self.fileDir, file)
        local attr = lfs.attributes(fullPath)
        if attr and attr.mode == "file" and file:match("^WoWCombatLog") and attr.modification > lastModificationTime then
            self.logFile = file
            lastModificationTime = attr.modification
        end
    end
    print(string.format("Log Found! (%s)", self.logFile))
end

function DataProcess:ChangeDir(dir)
    self.fileDir = dir
    self:RefreshFilePath()
end

function DataProcess:ProcessCombatant(combatantLine)
    local function parseNestedData(input)
        local parsedTbl = {}
        local inLevel = 0
        local currentString = ""

        for char in input:gmatch(".") do
            if char == "(" or char == "[" then inLevel = inLevel + 1
            elseif char == ")" or char == "]" then inLevel = inLevel - 1 end

            if (char == "," or char == ")" or char == "]") and inLevel == 0 then
                if currentString ~= "" then
                    if char == ")" or char == "]" then
                        ---@diagnostic disable-next-line: cast-local-type
                        currentString = parseNestedData(currentString:sub(2))
                    end
                    table.insert(parsedTbl, currentString)
                    currentString = ""
                end
            else
                currentString = currentString .. char
            end
        end

        return parsedTbl
    end
    local parsedPlayerData = parseNestedData(combatantLine)
    self.groupData[parsedPlayerData[2]] = {
        rawData = parsedPlayerData,
        color = classColors[specToClass[tonumber(parsedPlayerData[25])]],
        name = "",
        coloredName = ""
    }
end
local testEvents = {}
function DataProcess:Cleu(date, timestamp, subEvent, ...)
    local _, sourceGUID, sourceName = ...
    if self.groupData[sourceGUID] then
        local normalizedName = sourceName:match("[^-]+")
        self.groupData[sourceGUID].name = normalizedName
        self.groupData[sourceGUID].coloredName = self:ColorString(normalizedName, self.groupData[sourceGUID].color)
    end
    if advancedEvents[subEvent] then
        local infoGUID, ownerGUID, currentHP, maxHP, attackPower, spellPower, armor, absorb, powerType, currentPower, maxPower, powerCost, positionX, positionY, uiMapID, facing, level = select(advancedEvents[subEvent], ...)
        if self.groupData[infoGUID] then
            self.groupData[infoGUID].position = {
                map = uiMapID,
                posX = positionX,
                posY = positionY,
                face = facing
            }
        end
    end

    if subEvent == "ENCOUNTER_START" then
        local _, encounterId, encounterName, difficultyId, groupSize, instanceId = ...
        self.encounterData.current = {
            id = encounterId,
            name = encounterName,
            difficulty = difficultyId,
            groupSize = groupSize,
            instance = instanceId
        }
    elseif subEvent == "ENCOUNTER_END" then
        local success, fightTime = select(6, ...)
        local lastEncounter = self.encounterData.current or {}
        lastEncounter.success = success == "1" and true or false
        lastEncounter.duration = fightTime
        lastEncounter.durationString = self:FormatMilliseconds(fightTime)
        self.encounterData.last = lastEncounter
        self.encounterData.current = {}
    end
    for k, v in pairs(self.encounterData.last) do
        print(k,v)
    end
end

function DataProcess:ReadFile()
    local file = io.open(string.format("%s\\%s",self.fileDir, self.logFile), "r")
    if file then
        local currentFileSize = file:seek("end")
        if self.lastFileSize == 0 then self.lastFileSize = currentFileSize end
        if currentFileSize > self.lastFileSize then
            file:seek("set", self.lastFileSize)
            self.lastFileSize = currentFileSize

            local newContent = file:read("*a")
            for line in newContent:gmatch("[^\r\n]+") do
                local cleu = {}
                local event = {}
                local skippedString
                -- skippedString shit is cause "Djaruun, Pillar of the Elder Flame" splits into 2 values and fucks the Advanced Logging
                for item in line:gmatch("[^,]+") do
                    local _, count = item:gsub('"', "")
                    if count == 1 and skippedString then
                        item = item .. ", " .. skippedString
                        skippedString = nil
                        item = item:gsub('"', "")
                        table.insert(cleu, item)
                    elseif count == 1 then
                        skippedString = item
                    else
                        item = item:gsub('"', "")
                        table.insert(cleu, item)
                    end
                end
                for item in cleu[1]:gmatch("[^%s]+") do table.insert(event, item) end
                local date, timestamp, subEvent = unpack(event)

                if subEvent == "COMBATANT_INFO" then
                    self:ProcessCombatant(line)
                else
                    self:Cleu(date, timestamp, subEvent, unpack(cleu))
                end
            end 
        end
        file:close()
    else
        print("Error opening the file.")
    end
end

local cL = DataProcess:New()
cL:ChangeDir("C:\\Users\\lmjoh\\Desktop\\TestOverlayLua")
cL.lastFileSize = 1
cL:ReadFile()
for _, playerTbl in pairs(cL.groupData) do
    print(cL:ColorString(playerTbl.name, playerTbl.color))
end

for k,v in pairs(testEvents) do
    local full = ""
    for _, j in pairs(v) do
        full = full .. j .. ","
    end
    --print(k..","..full)
end