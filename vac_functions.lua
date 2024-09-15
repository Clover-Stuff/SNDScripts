--[[ 
This file needs to be dropped inside %appdata%\XIVLauncher\pluginConfigs\SomethingNeedDoing\
So it should look like this %appdata%\XIVLauncher\pluginConfigs\SomethingNeedDoing\vac_functions.lua
It contains the functions required to make the scripts work

####################
##    Version     ##
##     1.0.0      ##
####################

-> 1.0.0: Initial release

#################
## TO DO STUFF ##
#################

EatFood() function
UseItem() function
Closest aetheryte to player and distance calculations
Add flight to Movement() function
Refactor Teleporter() function
Add fate related functions
Convert over to /callback from /pcall
Add error handling for nil/"" and convert lowercase or tostring/tonumber etc

#####################################
#####################################
#####################################
###################################]]

function LoadFileCheck()
    LogInfo("[VAC] Successfully loaded the vac functions file")
end

-- this part just loads all the lists into memory to use with various functions
local vac_lists = dofile(os.getenv("appdata") .. "\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\vac_lists.lua")
DC_With_Worlds = vac_lists.DC_With_Worlds
Item_List = vac_lists.Item_List
Job_List = vac_lists.Job_List
Quest_List = vac_lists.Quest_List
World_ID_List = vac_lists.World_ID_List
Zone_List = vac_lists.Zone_List
GC_MIN_List = vac_lists.GC_MIN_List
GC_BTN_List = vac_lists.GC_BTN_List
GC_FSH_List = vac_lists.GC_FSH_List
Fate_List = vac_lists.Fate_List

-- Usage: EnsureFolderExists("\\path\\to\\your\\folder")
--
-- Call this to check if a folder exists at the path you provide, if it doesn't it'll create it
function EnsureFolderExists(folder_path)
    -- Try to create a temporary file in the folder
    local temp_file_path = folder_path .. "\\.temp_file"
    local file = io.open(temp_file_path, "w")

    -- If the file couldn't be opened, the folder doesn't exist
    if not file then
        -- Folder doesn't exist, create it
        os.execute("mkdir -p " .. folder_path)
    else
        -- Folder exists, close and remove the temporary file
        file:close()
        os.remove(temp_file_path)
    end
end

-- InteractAndWait()
--
-- Interacts with the current target and waits until the player is available again before proceeding
function InteractAndWait()
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

    Dismount()
    Sleep(0.5)
    yield("/interact")

    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)
end

-- Usage: LoginCheck()
-- Waits until player NamePlate is visible and player is ready
function LoginCheck()
    repeat
        Sleep(0.1)
    until IsAddonVisible("NamePlate") and IsPlayerAvailable()
end

-- Usage: VNavChecker()
-- Waits until player no longer has a nav path running
-- Very likely getting removed
function VNavChecker() --Movement checker, does nothing if moving
    repeat
        Sleep(0.1)
    until not PathIsRunning() and IsPlayerAvailable()
end

-- Interact()
--
-- Just interacts with the current target
function Interact()
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26) and not IsMoving() or GetCharacterCondition(32)

    Dismount()
    Sleep(0.5)
    yield("/interact")
    
    repeat
        Sleep(0.1)
    until not IsPlayerCasting() and not GetCharacterCondition(31)
end

-- Usage: AttuneAetheryte()
-- Attunes with the Aetheryte, exits out of menus if already attuned
function AttuneAetheryte()
    -- Wait until the player is ready to interact
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26) and not IsMoving() and not (GetCharacterCondition(45) or GetCharacterCondition(51))

    -- Target and interact with the Aetheryte
    Target("Aetheryte")
    Sleep(0.1)
    Interact()

    -- If the player is already attuned, exit the menu
    if (GetCharacterCondition(31) or GetCharacterCondition(32)) and IsAddonVisible("SelectString") then
        repeat
            Sleep(0.1)
        until IsAddonVisible("SelectString")

        Sleep(0.5)
        yield("/pcall SelectString true 3")

        -- Wait until the menu is no longer visible
        repeat
            Sleep(0.1)
        until not IsAddonVisible("SelectString")
    end

    -- Wait until player is available
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not (GetCharacterCondition(31) or GetCharacterCondition(32))
    
    Sleep(1.0)
end

-- Usage: IsInParty()
-- Checks if player is in a party, returns true if in party, returns false if not in party
function IsInParty()
    return GetPartyMemberName(0) ~= nil and GetPartyMemberName(0) ~= "" and not GetCharacterCondition(45)
end

-- Usage: ZoneCheck("Limsa Lominsa Lower Decks")
--
-- Checks if you're currently in the provided zone, you can supply zone name or aetheryte name
function ZoneCheck(zone_name)
    local zone_id = FindZoneID(zone_name)
    if zone_id == nil then
        zone_id = FindZoneIDByAetheryte(zone_name)
    end
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26) and not GetCharacterCondition(32)

    if GetZoneID() == zone_id then
        return true  -- Returns true if zone matches
    else
        return false -- Returns false if zone doesn't match
    end
end

-- Usage: Echo("meow")
--
-- prints provided text into chat
function Echo(text)
    yield("/echo " .. tostring(text))
end

-- Usage: Sleep(0.1) or Sleep("0.1")
--
-- replaces yield wait spam, halts the script for X seconds
function Sleep(time)
    yield("/wait " .. tostring(time))
end

-- Usage: ZoneTransitions()
-- Zone transition checker, used if you need to path between two zones and waits until player is available
function ZoneTransitions()
    -- Check if player is in transition between zones
    while not (GetCharacterCondition(45) or GetCharacterCondition(51)) do
        Sleep(0.1)
    end

    -- Wait until player no longer in transition between zones
    while GetCharacterCondition(45) or GetCharacterCondition(51) do
        Sleep(0.1)
    end

    -- Check if player is available
    while not IsPlayerAvailable() or IsPlayerCasting() or GetCharacterCondition(26) or GetCharacterCondition(32) do
        Sleep(0.1)
    end
end

-- Usage: QuestNPC("SelectYesno"|"CutSceneSelectString", true, 0)
--
-- NPC interaction handler, only supports one dialogue option for now. DialogueOption optional.
function QuestNPC(DialogueType, DialogueConfirm, DialogueOption)
    while not GetCharacterCondition(32) do
        yield("/interact")
        Sleep(0.1)
    end
    if DialogueConfirm then
        repeat
            Sleep(0.1)
        until IsAddonVisible(DialogueType)
        if DialogueOption == nil then
            repeat
                Sleep(0.1)
            until IsAddonVisible(DialogueType)

            yield("/pcall " .. DialogueType .. " true 0")

            repeat
                Sleep(0.1)
            until not IsAddonVisible(DialogueType)
        else
            repeat
                Sleep(0.1)
            until IsAddonVisible(DialogueType)

            yield("/pcall " .. DialogueType .. " true " .. DialogueOption)

            repeat
                Sleep(0.1)
            until not IsAddonVisible(DialogueType)
        end
    end
    repeat
        Sleep(0.1)
    until IsPlayerAvailable()
end

-- Usage: QuestNPCSingle("SelectYesno"|"CutSceneSelectString", true, 0)
--
-- NPC interaction handler. dialogue_option optional.
function QuestNPCSingle(dialogue_type, dialogue_confirm, dialogue_option)
    while not GetCharacterCondition(32) do
        yield("/interact")
        Sleep(0.5)
    end
    if dialogue_confirm then
        repeat
            Sleep(0.1)
        until IsAddonReady(dialogue_type)
        Sleep(0.5)
        if dialogue_option == nil then
            yield("/pcall " .. dialogue_type .. " true 0")
            Sleep(0.5)
        else
            yield("/pcall " .. dialogue_type .. " true " .. dialogue_option)
            Sleep(0.5)
        end
    end
end

-- Usage: FindNearestObject("Heckler Imp")
--
-- Returns the XYZ coordinates of the nearest object with that name
function FindNearestObject(object_name)
    local object_x_pos = GetObjectRawXPos(object_name)
    local object_y_pos = GetObjectRawYPos(object_name)
    local object_z_pos = GetObjectRawZPos(object_name)

    if object_x_pos == 0.0 and object_y_pos == 0.0 and object_z_pos == 0.0 then
        return nil, nil, nil
    else
        return object_x_pos, object_y_pos, object_z_pos
    end
end

-- Usage: TargetNearestEnemy("Heckler Imp", 20)
--
-- Targets the nearest enemy of the name you supply, within the radius
function TargetNearestEnemy(target_name, radius)
    local smallest_distance = 10000000000000.0
    local closest_target
    local objectKind = 0                                                                             -- Set objectkind to 0 so GetNearbyObjectNames pulls everything nearby
    local radius = radius or 0
    local nearby_objects = GetNearbyObjectNames(radius ^ 2, objectKind)                              -- Pull all nearby objects/enemies into a list
    if nearby_objects.Count > 0 then                                                                 -- Starts a loop if there's more than 0 nearby objects
        for i = 0, nearby_objects.Count - 1 do                                                       -- loops until no more objects
            yield("/target " .. nearby_objects[i])
            if not GetTargetName() or nearby_objects[i] ~= GetTargetName() then                      -- If target name is nil, skip it
            elseif GetDistanceToTarget() < smallest_distance and GetTargetName() == target_name then -- if object matches the target_name and the distance to target is smaller than the current smallest_distance, proceed
                smallest_distance = GetDistanceToTarget()
                closest_target = GetTargetName()
            end
        end
        ClearTarget()
        if closest_target then yield("/target " .. closest_target) end -- after the loop ends it targets the closest enemy
    end
    return closest_target
end

-- Usage: FindDistanceToObject("Goblin")
--
-- Returns the distance from the player to an object
function FindDistanceToObject(object_name)
    local object_x_pos = GetObjectRawXPos(object_name)
    local object_y_pos = GetObjectRawYPos(object_name)
    local object_z_pos = GetObjectRawZPos(object_name)

    local function floor_position(pos)
        return math.floor(pos + 0.5)
    end

    local object_x_position_floored = floor_position(object_x_pos)
    local object_y_position_floored = floor_position(object_y_pos)
    local object_z_position_floored = floor_position(object_z_pos)

    local xpos = floor_position(GetPlayerRawXPos())
    local ypos = floor_position(GetPlayerRawYPos())
    local zpos = floor_position(GetPlayerRawZPos())

    local function DistanceToTarget(xpos, ypos, zpos)
        return math.sqrt(
            (xpos - object_x_position_floored) ^ 2 +
            (ypos - object_y_position_floored) ^ 2 +
            (zpos - object_z_position_floored) ^ 2
        )
    end

    local distance_to_object = DistanceToTarget(xpos, ypos, zpos)

    return distance_to_object
end

-- Usage: FindDistanceToPos(x, y, z)
--
-- Returns the distance from the player to a position
function FindDistanceToPos(pos_x, pos_y, pos_z)
    local function floor_position(pos)
        return math.floor(pos + 0.5)
    end

    local object_x_position_floored = floor_position(pos_x)
    local object_y_position_floored = floor_position(pos_y)
    local object_z_position_floored = floor_position(pos_z)

    local xpos = floor_position(GetPlayerRawXPos())
    local ypos = floor_position(GetPlayerRawYPos())
    local zpos = floor_position(GetPlayerRawZPos())

    local function DistanceToTarget(xpos, ypos, zpos)
        return math.sqrt(
            (xpos - object_x_position_floored) ^ 2 +
            (ypos - object_y_position_floored) ^ 2 +
            (zpos - object_z_position_floored) ^ 2
        )
    end

    local distance_to_object = DistanceToTarget(xpos, ypos, zpos)

    return distance_to_object
end

-- Usage: FindAndKillTarget("Heckler Imp", 20)
--
-- Uses TargetNearestEnemy() to find and kill the provided target within the specified radius
function FindAndKillTarget(target_name, radius)
    local radius = radius or 50
    local auto_attack_triggered = false
    local target_x_pos, target_y_pos, target_z_pos = FindNearestObject(target_name)

    if target_x_pos == nil then
        return
    end

    local distance_to_target = FindDistanceToPos(target_x_pos, target_y_pos, target_z_pos)

    if distance_to_target > radius then
        return
    end

    Movement(target_x_pos, target_y_pos, target_z_pos, 4)
    TargetNearestEnemy(target_name, radius)

    local dist_to_target = GetDistanceToTarget()

    while GetTargetHP() > 0 and dist_to_target <= radius do
        if GetCharacterCondition(4) then
            repeat
                Dismount()
                Sleep(0.1)
            until not GetCharacterCondition(4)
        end

        yield("/rotation manual")

        repeat
            if (GetDistanceToTarget() <= 4) and PathIsRunning() then
                yield("/vnav stop")
            end
            if not (GetDistanceToTarget() <= 4) and not PathIsRunning() then
                if not auto_attack_triggered then
                    yield("/vnavmesh movetarget")
                    Sleep(0.1)
                end
            end

            if GetDistanceToTarget() <= 4 and not auto_attack_triggered then
                DoAction("Auto-attack")
                Sleep(0.1)
                if IsTargetInCombat() and GetCharacterCondition(26) then
                    auto_attack_triggered = true
                end
            end

            Sleep(0.05)
        until GetTargetHP() <= 0

        yield("/vnavmesh stop")
    end
    Sleep(0.5)
    if GetCharacterCondition(26) then
        yield("/rotation auto")
        repeat
            Sleep(0.1)
        until not GetCharacterCondition(26)
    end
end

-- Usage: GetNodeTextLookupUpdate("_ToDolist",16,3,4) // GetNodeTextLookupUpdate("_ToDolist",16,3)
--
-- function that's honestly nothing but tragic, is only called by Questchecker and Nodescanner, could be called manually.
function GetNodeTextLookupUpdate(get_node_text_type, get_node_text_location, get_node_text_location_1, get_node_text_location_2)
    bypass = "next task"
    if get_node_text_location_2 == nil then
        LogInfo("[VAC] GetNodeTextLookupUpdate: " .. get_node_text_type .. " " .. get_node_text_location .. " " .. get_node_text_location_1)
            get_node_text = GetNodeText(get_node_text_type, get_node_text_location, get_node_text_location_1)
        if get_node_text == get_node_text_location_1 then
            return bypass
        else
            return get_node_text
        end
        --- i hate
    else
        LogInfo("[VAC] GetNodeTextLookupUpdate2: " .. get_node_text_type .. " " .. get_node_text_location .. " " .. get_node_text_location_1 .. " " .. get_node_text_location_2)
        get_node_text = GetNodeText(get_node_text_type, get_node_text_location, get_node_text_location_1,get_node_text_location_2)
        if get_node_text == get_node_text_location_2 then
            return bypass
        else
            return get_node_text
        end
        --- this function
    end
    Echo("GetNodeTextLookupUpdate went wrong somewhere")
end

-- Usage: QuestChecker(ArcanistEnemies[3], 50, "_ToDoList", "Slay little ladybugs.")
--
-- This is used to find the provided target in the _ToDolist node and kill them until no more targets are needed
function QuestChecker(target_name, target_distance, get_node_text_type, get_node_text_match)
    local get_node_text_location, get_node_text_location_1, get_node_text_location_2 = NodeScanner(get_node_text_type, get_node_text_match)
    local function extractTask(text)
        local task = string.match(text, "^(.-)%s%d+/%d+$")
        return task or text
    end
    while true do
        updated_node_text = GetNodeTextLookupUpdate(get_node_text_type, get_node_text_location, get_node_text_location_1, get_node_text_location_2)
        LogInfo("[VAC] updated_node_text: " .. updated_node_text)
        LogInfo("[VAC] Extract: " .. extractTask(updated_node_text))
        local last_char = string.sub(updated_node_text, -1)
        LogInfo("[VAC] last char: " .. updated_node_text)
        Sleep(2.0)
        if updated_node_text == get_node_text_match or not string.match(last_char, "%d") then
            break
        end
        FindAndKillTarget(target_name, target_distance)
    end
    -- checks if player in combat before ending rotation solver
    if not GetCharacterCondition(26) then
        yield("/rotation off")
    end
end

-- Usage: NodeScanner("_ToDoList", "Slay wild dodos.")
--
-- scans provided node type for node that has provided text and returns minimum 2 but up to 3 variables with the location which you can use with GetNodeText()
--
-- this will fail if the node is too nested and scanning deeper than i am currently is just not a good idea i think
function NodeScanner(get_node_text_type, get_node_text_match)
    node_type_count = tonumber(GetNodeListCount(get_node_text_type))
    local function extractTask(text)
        local task = string.match(text, "^(.-)%s*%d*/%d*$")
        return task or text
    end
    for location = 0, node_type_count do
        for sub_node = 0, 60 do
            Sleep(0.0001)
            local node_check = GetNodeText(get_node_text_type, location, sub_node)
            local clean_node_text = extractTask(node_check)
            if clean_node_text == nil then
            else
                --LogInfo([VAC] tostring(clean_node_text))
            end
            if clean_node_text == get_node_text_match then
                return location, sub_node
            end
        end
    end
    -- deeper scan
    for location = 0, node_type_count do
        for sub_node = 0, 60 do
            for sub_node2 = 0, 20 do
                Sleep(0.0001)
                local node_check = GetNodeText(get_node_text_type, location, sub_node, sub_node2)
                local clean_node_text = extractTask(node_check)
                if clean_node_text == nil then
                else
                    --LogInfo([VAC] tostring(clean_node_text))
                end
                if clean_node_text == get_node_text_match then
                    return location, sub_node, sub_node2
                end
            end
        end
    end
end

-- Usage: OpenHuntLog(9, 0), Defaults to rank 0 if empty
-- Valid classes: 0 = GLA, 1 = PGL, 2 = MRD, 3 = LNC, 4 = ARC, 5 = ROG, 6 = CNJ, 7 = THM, 8 = ACN, 9 = GC
-- Valid ranks/pages: 0-4 for jobs, 0-2 for GC
-- Valid show: 0 = show all, 1 = show complete, 2 = show incomplete
-- The first variable is the class to open, the second is the rank to open
function OpenHuntLog(class, rank, show)
    local defaultshow = 2
    local defaultrank = 0  --
    local defaultclass = 9 -- this is the gc log
    rank = rank or defaultrank
    class = class or defaultclass
    show = show or defaultshow
    -- 1 Maelstrom
    -- 2 Twin adders
    -- 3 Immortal flames

    repeat
        yield("/huntinglog")
        Sleep(0.5)
    until IsAddonReady("MonsterNote")

    local gc_id = GetPlayerGC()

    if class == 9 then
        yield("/pcall MonsterNote false 3 9 " .. tostring(gc_id))
    else
        yield("/pcall MonsterNote false 0 " .. tostring(class))
    end

    Sleep(0.3)
    yield("/pcall MonsterNote false 1 " .. rank)
    Sleep(0.3)
    yield("/pcall MonsterNote false 2 " .. show)
end

-- Usage: CloseHuntLog()
-- Closes the Hunting Log if open
function CloseHuntLog()
    repeat
        yield("/huntinglog")
        Sleep(0.5)
    until not IsAddonVisible("MonsterNote")
end

-- Usage: HuntLogCheck("Amalj'aa Hunter", 9, 0)
-- Valid classes: 0 = GLA, 1 = PGL, 2 = MRD, 3 = LNC, 4 = ARC, 5 = ROG, 6 = CNJ, 7 = THM, 8 = ACN, 9 = GC
-- Valid ranks/pages: 0-4 for jobs, 0-2 for GC
-- Opens and checks current progress and returns a true if finished or a false if not
function HuntLogCheck(target_name, class, rank)
    OpenHuntLog(class, rank, 2)
    local node_text = ""
    local function CheckTargetAmountNeeded(sub_node)
        local target_amount = tostring(GetNodeText("MonsterNote", 2, sub_node, 3))
        local first_number = tonumber(target_amount:sub(1, 1))
        local last_number = tonumber(target_amount:sub(-1))

        if first_number == last_number then
            return 0
        else
            return last_number - first_number
        end
    end

    local function FindTargetNode()
        for sub_node = 5, 60 do
            Sleep(0.001)
            node_text = tostring(GetNodeText("MonsterNote", 2, sub_node, 4))
            if node_text == target_name then
                return sub_node
            end
        end
    end

    local target_amount_needed_node = FindTargetNode()

    if not target_amount_needed_node then
        LogInfo("[VAC] Couldn't find " .. target_name .. " in hunting log, likely already finished")
        return false, 0
    else
        LogInfo("[VAC] Found " .. target_name .. " in hunting log, time to hunt")
        local target_amount_needed = CheckTargetAmountNeeded(target_amount_needed_node)

        if target_amount_needed == 0 then
            CloseHuntLog()
            return false, target_amount_needed
        else
            CloseHuntLog()
            return true, target_amount_needed
        end
    end
end

-- Usage: DoHuntLog("Amalj'aa Hunter", 40, 9, 0)
-- Valid classes: 0 = GLA, 1 = PGL, 2 = MRD, 3 = LNC, 4 = ARC, 5 = ROG, 6 = CNJ, 7 = THM, 8 = ACN, 9 = GC
-- Valid ranks/pages: 0-4 for jobs, 0-2 for GC
-- Opens and checks current progress of Hunting Log for automated killing
function DoHuntLog(target_name, target_distance, class, rank)
    local finished = false
    local TargetsLeft, AmountLeft = HuntLogCheck(target_name, class, rank)

    if AmountLeft > 0 and TargetsLeft then
        while not finished do
            if AmountLeft > 0 then
                repeat
                    FindAndKillTarget(target_name, target_distance)
                    AmountLeft = AmountLeft - 1
                    Sleep(3)
                until AmountLeft == 0
            end
            TargetsLeft, AmountLeft = HuntLogCheck(target_name, class, rank)
            if AmountLeft == 0 then
                finished = true
            end
        end

        if not GetCharacterCondition(26) then
            yield("/rotation off")
        end
    end
end

-- Usage: Teleporter("Limsa", "tp") or Teleporter("gc", "li") or Teleporter("Vesper", "item")
-- Options: location = teleport location, tp_kind = tp, li, item
-- Will teleport player to specified location
function Teleporter(location, tp_kind) -- Teleporter handler
    tp_kind = string.lower(tp_kind)
    local cast_time_buffer = 5         -- Just in case a buffer is required, teleports are 5 seconds long. Slidecasting, ping and fps can affect casts
    local max_retries = 10             -- Teleporter retry amount, will not tp after number has been reached for safety
    local retries = 0

    -- Initial check to ensure player can teleport
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26) and not GetCharacterCondition(32) -- 26 is combat, 32 is quest event

    -- Try teleport, retry until max_retries is reached
    if tp_kind == "tp" then
        while retries < max_retries do
            -- Stop lifestream only once per teleport attempt
            if FindZoneIDByAetheryte(location) == GetZoneID() then
                LogInfo("[VAC] Already in the right zone")
                break
            end

            -- Attempt teleport
            if not IsPlayerCasting() then
                yield("/tp " .. location)
                Sleep(2.0) -- Wait to check if casting starts

                -- Check if the player started casting
                if IsPlayerCasting() then
                    Sleep(cast_time_buffer) -- Wait for cast to complete
                end
            end

            -- Check if the teleport was successful
            if GetCharacterCondition(45) or GetCharacterCondition(51) then -- 45 is BetweenAreas, 51 is BetweenAreas51
                LogInfo("[VAC] Teleport successful.")
                break
            end

            -- Teleport retry increment
            retries = retries + 1
            LogInfo("[VAC] Retrying teleport, attempt #" .. retries)
        end

        -- Teleporter failed handling
        if retries >= max_retries then
            local attempt_word = (max_retries == 1) and "attempt" or "attempts"
            LogInfo("[VAC] Teleport failed after " .. max_retries .. " " .. attempt_word .. ".")
            Echo("Teleport failed after " .. max_retries .. " " .. attempt_word .. ".")
        end
    elseif tp_kind == "li" then
        while retries < max_retries do
            if not IsPlayerCasting() then
                yield("/li " .. location)
                Sleep(2.0) -- give lifestream some time to start
            end

            if LifestreamIsBusy() then
                repeat
                    Sleep(0.1)
                until not LifestreamIsBusy() and IsPlayerAvailable()
                break
            end
            retries = retries + 1
            LogInfo("[VAC] Retrying lifestream, attempt #" .. retries)
        end
        -- Reset lifestream_stopped for next retry
        if retries >= max_retries then
            local attempt_word = (max_retries == 1) and "attempt" or "attempts"
            LogInfo("[VAC] Lifestream failed after " .. max_retries .. " " .. attempt_word .. ".")
            Echo("Lifestream failed after " .. max_retries .. " " .. attempt_word .. ".")
            yield("/lifestream stop") -- Not always needed but removes lifestream ui
        end
    else
        Echo('Invalid option "' .. tp_kind .. '", valid options are li and tp')
    end
end

-- Usage: UseItemTeleport("Maelstrom")
-- Will use specified teleport location item for teleporting
function UseItemTeleport(location)
    -- TP items mapped
    local teleport_items = {
        ["Immortal Flames"] = "Immortal Flames Aetheryte Ticket",
        ["Maelstrom"] = "Maelstrom Aetheryte Ticket",
        ["Twin Adder"] = "Twin Adder Aetheryte Ticket",
        ["Firmament"] = "Firmament Aetheryte Ticket",
        ["Vesper Bay"] = "Vesper Bay Aetheryte Ticket"
    }

    local item = teleport_items[location]

    if item then
        yield("/item " .. item)
    else
        LogInfo("[VAC] No teleport item found for: " .. location)
        Echo("No teleport item found for: " .. location)
    end
end

-- Usage: Mount("SDS Fenrir")
-- Attempts to use specified mount if player has mounts unlocked
-- Will use "Company Chocobo" if left empty
-- Stores if the locked mount message in Mount() has been sent already or not
local mount_message = false
function Mount(mount_name)
    local max_retries = 10     -- Maximum number of retries
    local retry_interval = 1.0 -- Time interval between retries in seconds
    local retries = 0          -- Counter for the number of retries

    -- Check if the player has unlocked mounts by checking the quest completion
    if not (IsQuestComplete(66236) or IsQuestComplete(66237) or IsQuestComplete(66238)) then
        if not mount_message then
            Echo('You do not have a mount unlocked, please consider completing the "My Little Chocobo" quest.')
        else
            mount_message = true
        end
        return
    end

    if TerritorySupportsMounting() then -- Check if territory is mountable using the snd function
        -- Return if the player is already mounted
        if GetCharacterCondition(4) then
            return
        end

        -- Initial check to ensure the player can mount
        repeat
            Sleep(0.1)
        until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

        -- Retry loop for mounting with a max retry limit (set above)
        while retries < max_retries do
            -- Attempt to mount using the chosen mount or Mount Roulette if none
            if mount_name == nil then
                yield('/mount "Company Chocobo"')
            else
                yield('/mount "' .. mount_name .. '"')
            end

            -- Wait for the retry interval
            Sleep(retry_interval)

            -- Exit loop if the player mounted
            if GetCharacterCondition(4) then
                local attempt_word = (retries == 1) and "retry" or "retries"
                Echo("Successfully mounted after " .. retries .. " " .. attempt_word .. ".")
                break
            end

            -- Increment the retry counter
            retries = retries + 1
        end

        -- Check if max retries were reached without success
        if retries >= max_retries then
            local attempt_word = (max_retries == 1) and "retry" or "retries"
            Echo("Failed to mount after " .. max_retries .. " " .. attempt_word .. ".")
        end

        -- Check player is available and mounted
        repeat
            Sleep(0.1)
        until IsPlayerAvailable() and GetCharacterCondition(4)
    else
        Echo("Not possible to mount here")
        return
    end
end

-- Usage: LogOut()
-- Logs the player out of the game
function LogOut()
    yield("/logout")

    repeat
        Sleep(0.1)
    until IsAddonVisible("SelectYesno")

    yield("/pcall SelectYesno true 4")

    repeat
        Sleep(0.1)
    until not IsAddonVisible("SelectYesno")
end

-- Usage: Movement(674.92, 19.37, 436.02) // Movement(674.92, 19.37, 436.02, 15)
-- Moves player to specified x y z coordinates with optional distance value to stop movement when player is within specified distance
-- Will automatically mount, unstuck the player if player is stuck and stop within 2.5 distance of the destination
function Movement(x_position, y_position, z_position, range)
    range = range or 2.5                 -- Default stopping range if not provided
    local stop_buffer = 1.0              -- Increased buffer to ensure stopping before reaching the exact target
    local max_retries = 10               -- Max number of retries to start moving
    local stuck_check_interval = 0.50    -- Interval in seconds to check if stuck
    local stuck_threshold_seconds = 4.0  -- Time before considering the player stuck
    local min_progress_distance = 0.1    -- Minimum distance considered progress
    local min_distance_for_mounting = 15 -- Distance threshold for deciding to mount

    -- Function to calculate the squared distance to the target
    local function GetSquaredDistanceToTarget(xpos, ypos, zpos)
        local dx = xpos - x_position
        local dy = ypos - y_position
        local dz = zpos - z_position
        return dx * dx + dy * dy + dz * dz
    end

    -- Function to check if the current position is within the target range (using squared distance)
    local function IsWithinRange(xpos, ypos, zpos)
        -- Check if the squared distance is less than or equal to the squared range plus buffer
        return GetSquaredDistanceToTarget(xpos, ypos, zpos) <= (range + stop_buffer) * (range + stop_buffer)
    end

    -- Initiate movement towards the destination using vnavmesh
    local function NavToDestination()
        NavReload() -- Reload vnavmesh to ensure it's ready

        -- Wait until vnavmesh is ready
        if not NavIsReady() then
            repeat
                Sleep(0.05)
            until NavIsReady()
        end

        local retries = 0 -- Initialize retry counter

        repeat
            -- Get player's current position
            local xpos = GetPlayerRawXPos()
            local ypos = GetPlayerRawYPos()
            local zpos = GetPlayerRawZPos()

            -- Calculate squared distance to target
            local squared_distance_to_target = GetSquaredDistanceToTarget(xpos, ypos, zpos)

            -- Check if the player should mount based on distance and conditions
            if squared_distance_to_target > min_distance_for_mounting * min_distance_for_mounting and TerritorySupportsMounting() and (IsQuestComplete(66236) or IsQuestComplete(66237) or IsQuestComplete(66238)) then
                -- Attempt to mount until successful
                repeat
                    Mount()
                    Sleep(0.1)
                until GetCharacterCondition(4) and IsPlayerAvailable()
            end

            -- Start moving towards the destination
            yield("/vnav moveto " .. x_position .. " " .. y_position .. " " .. z_position)
            retries = retries + 1
            Sleep(0.05)
        until PathIsRunning() or retries >= max_retries -- Stop if path is running or max retries reached

        Sleep(0.05)
    end

    NavToDestination() -- Call the function to start navigating to the destination

    local stuck_timer = 0 -- Timer to track how long the player has been stuck
    local previous_squared_distance_to_target = nil -- Store the previous squared distance to target
    local previous_relative_position = nil -- Store player's previous position relative to the target

    while true do
        -- Check if the player is teleporting or in a loading state
        if GetCharacterCondition(45) or GetCharacterCondition(51) then
            yield("/vnav stop") -- Temporarily stop navmesh

            -- Wait for teleporting or loading to finish
            repeat
                Sleep(0.1)
            until not GetCharacterCondition(45) and not GetCharacterCondition(51)

            -- Resume navmesh after conditions clear
            NavToDestination()
        end

        -- Get player's current position
        local xpos = GetPlayerRawXPos()
        local ypos = GetPlayerRawYPos()
        local zpos = GetPlayerRawZPos()
        Sleep(0.05)

        -- Calculate the current squared distance to the target
        local current_squared_distance_to_target = GetSquaredDistanceToTarget(xpos, ypos, zpos)

        -- If the player is within the target range, stop movement once the player is within range
        if IsWithinRange(xpos, ypos, zpos) then
            yield("/vnav stop")
            break
        end

        -- Stuck check logic
        if previous_squared_distance_to_target and previous_relative_position then
            local dx = xpos - previous_relative_position.x
            local dy = ypos - previous_relative_position.y
            local dz = zpos - previous_relative_position.z
            local squared_distance_traveled = dx * dx + dy * dy + dz * dz

            -- If the player is not making sufficient progress, increase the stuck timer
            if current_squared_distance_to_target >= previous_squared_distance_to_target - min_progress_distance * min_progress_distance and 
               squared_distance_traveled < min_progress_distance * min_progress_distance then
                stuck_timer = stuck_timer + stuck_check_interval
            else
                stuck_timer = math.max(0, stuck_timer - stuck_check_interval / 2)
            end
        end

        -- If the stuck timer exceeds the threshold, attempt to get unstuck
        if stuck_timer >= stuck_threshold_seconds then
            DoGeneralAction("Jump")
            Sleep(0.1)
            NavReload()
            NavToDestination()
            stuck_timer = 0
        end

        -- Update previous distance and position
        previous_squared_distance_to_target = current_squared_distance_to_target
        previous_relative_position = { x = xpos, y = ypos, z = zpos }

        Sleep(0.05)
    end
end

-- Usage: OpenTimers()
-- this should probably be renamed to open gc timers
-- Opens the timers window
function OpenTimers()
    local last_trigger_time = os.time()
    local retry_interval = 5 -- x seconds interval between retries

    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerOccupied()

    yield("/timers")

    repeat
        local current_time = os.time()

        if current_time - last_trigger_time >= retry_interval then -- Activate once every x seconds
            yield("/timers")
            last_trigger_time = current_time                       -- Store the last trigger time
        end

        Sleep(0.1)
    until IsAddonReady("ContentsInfo")

    last_trigger_time = 0 -- Reset the trigger time

    repeat
        local current_time = os.time()
        if current_time - last_trigger_time >= retry_interval then -- Activate once every x seconds
            yield("/pcall ContentsInfo True 12 1")
            last_trigger_time = current_time                       -- Store the last trigger time
        end
        Sleep(0.1)
    until IsAddonReady("ContentsInfoDetail")
end

-- Usage: MarketBoardChecker()
--
-- just checks if the marketboard is open and keeps the script stopped until it's closed
function MarketBoardChecker()
    local ItemSearchWasVisible = false
    repeat
        Sleep(0.1)
        if IsAddonVisible("ItemSearch") then
            ItemSearchWasVisible = true
        end
    until ItemSearchWasVisible

    repeat
        Sleep(0.1)
    until not IsAddonVisible("ItemSearch")
end

-- Usage: BuyFromStore(1, 15) <--- buys 15 of X item
--
-- number_in_list is which item you're buying from the list, top item is 1, 2 is below that, 3 is below that etc...
-- only works for the "Store" addon window, i'd be careful calling it anywhere else
function BuyFromStore(number_in_list, amount)
    -- compensates for the top being 0
    number_in_list = number_in_list - 1
    local attempts = 0

    repeat
        attempts = attempts + 1
        Sleep(0.1)
    until (IsAddonReady("Shop") or attempts >= 100)

    -- attempts above 50 is about 5 seconds
    if attempts >= 100 then
        Echo("Waited too long, store window not found, moving on")
    end

    if IsAddonReady("Shop") and number_in_list and amount then
        yield("/pcall Shop True 0 " .. number_in_list .. " " .. amount)
        repeat
            Sleep(0.1)
        until IsAddonReady("SelectYesno")

        yield("/pcall SelectYesno true 0")
        Sleep(0.5)
        if IsAddonVisible("SelectYesno") then
            yield("/pcall SelectYesno true 0")
        end

        repeat
            Sleep(0.1)
        until not IsAddonReady("SelectYesno")

        Sleep(0.5)
    end
end

-- Usage: BuyFromStoreSingle(1)
--
-- Buys one item
-- number_in_list is which item you're buying from the list, top item is 1, 2 is below that, 3 is below that etc...
-- only works for the "Store" addon window, i'd be careful calling it anywhere else
function BuyFromStoreSingle(number_in_list)
    -- compensates for the top being 0
    number_in_list = number_in_list - 1
    local attempts = 0

    repeat
        attempts = attempts + 1
        Sleep(0.1)
    until (IsAddonReady("Shop") or attempts >= 100)

    -- attempts above 50 is about 5 seconds
    if attempts >= 100 then
        Echo("Waited too long, store window not found, moving on")
    end

    if IsAddonReady("Shop") and number_in_list then
        yield("/pcall Shop True 0 " .. number_in_list .. " 1")
        repeat
            Sleep(0.1)
        until IsAddonReady("SelectYesno")
        
        yield("/pcall SelectYesno true 0")
        Sleep(0.5)
        
        if IsAddonVisible("SelectYesno") then
            yield("/pcall SelectYesno true 0")
        end
        repeat
            Sleep(0.1)
        until not IsAddonReady("SelectYesno")

        Sleep(0.5)
    end
end

-- Usage: CloseStore()
-- Function used to close store windows
function CloseStore()
    if IsAddonVisible("Shop") then
        yield("/pcall Shop True -1")
    end

    repeat
        Sleep(0.1)
    until not IsAddonVisible("Shop")

    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)
end

-- Usage: Target("Storm Quartermaster")
-- TODO: target checking for consistency and speed
function Target(target)
    local target_command = "/target \"" .. target .. "\""
    repeat
        yield(target_command)
        Sleep(0.1)
    until string.lower(GetTargetName()) == string.lower(target)
end

-- Usage: DoGcRankUp()
--
-- Checks if you can rank up in your current gc, then it'll attempt to rank you up
function DoGcRankUp()
    -- check in case it's called when you can't rank up
    local can_rankup = CanGCRankUp()
    if not can_rankup then
        return
    end

    yield("/at e")
    local gc_id = GetPlayerGC()

    local gc_officer_names = {
        [1] = "Storm Personnel Officer",
        [2] = "Serpent Personnel Officer",
        [3] = "Flame Personnel Officer"
    }

    local function OpenAndAttemptRankup()
        local gc_target = gc_officer_names[gc_id]

        if gc_target then
            -- Target the correct GC officer
            Target(gc_target)
            yield("/lockon")
        else
            return
        end

        repeat
            yield("/pint")
            Sleep(0.1)
        until IsAddonReady("SelectString")

        yield("/pcall SelectString true 1")

        repeat
            Sleep(0.1)
        until IsAddonReady("GrandCompanyRankUp")

        yield("/pcall GrandCompanyRankUp true 0")
    end

    OpenAndAttemptRankup()
    
    Sleep(1.0)

    repeat
        Sleep(0.1)
    until IsPlayerAvailable()
end

-- Usage: can_rankup, next_rank = CanGCRankUp()
--
-- returns true and the next rank if you can rank up, returns false if you can't
function CanGCRankUp()
    local gc_rank_9_mission_complete = false
    local gc_rank_8_mission_complete = false
    local can_rankup = false
    local gc_rank = 0
    local gc_id = GetPlayerGC()
    local current_seals = 0
    local gc_ranks = {
        [1] = 0,
        [2] = 2000,
        [3] = 3000,
        [4] = 4000,
        [5] = 5000,
        [6] = 6000,
        [7] = 7000,
        [8] = 8000,
        [9] = 9000,
        [10] = 10000
    }

    if gc_id == 1 then -- checks if gc is maelstrom and checks if the quests are done
        gc_rank_8_mission_complete = IsQuestComplete(66664)
        gc_rank_9_mission_complete = IsQuestComplete(66667)
    elseif gc_id == 2 then -- checks if gc is twin adder and checks if the quests are done
        gc_rank_8_mission_complete = IsQuestComplete(66665)
        gc_rank_9_mission_complete = IsQuestComplete(66668)
    elseif gc_id == 3 then -- checks if gc is immortal flames and checks if the quests are done
        gc_rank_8_mission_complete = IsQuestComplete(66666)
        gc_rank_9_mission_complete = IsQuestComplete(66669)
    end

    if gc_id == 1 then -- checks if gc is maelstrom and adds seal amount to current_seals
        current_seals = GetItemCount(20)
        gc_rank = GetMaelstromGCRank()
    elseif gc_id == 2 then -- checks if gc is twin adder and adds seal amount to current_seals
        current_seals = GetItemCount(21)
        gc_rank = GetAddersGCRank()
    elseif gc_id == 3 then -- checks if gc is immortal flames and adds seal amount to current_seals
        current_seals = GetItemCount(22)
        gc_rank = GetFlamesGCRank()
    end

    local next_rank = gc_rank + 1 -- adds one so we know which gc rank we're attempting to rank up total
    if next_rank == 5 then
        local log_rank_1_complete = IsHuntLogComplete(9, 0)
        if log_rank_1_complete then
            can_rankup = true
        else
            Echo("You need to finish GC hunting log 1 to rank up more")
        end
    elseif next_rank == 8 then
        if not gc_rank_8_mission_complete then
            Echo('You need to finish the quest "Shadows Uncast" to rank up more')
        else
            can_rankup = true
        end
    elseif next_rank == 9 then
        local log_rank_2_complete = IsHuntLogComplete(9, 1)
        if log_rank_2_complete and gc_rank_9_mission_complete then
            can_rankup = true
        else
            if not log_rank_2_complete then
                Echo("You need to finish GC hunting log 2 to rank up more")
            end
            if not gc_rank_9_mission_complete then
                Echo('You need to finish the quest "Gilding The Bilious" to rank up more')
            end
        end
    else
        can_rankup = true
    end

    if current_seals > gc_ranks[next_rank] and next_rank <= 9 and can_rankup then -- excludes rank 10 and above as we don't handle that atm
        return true, next_rank
    else
        return false, next_rank
    end
end

-- Usage: OpenGcSupplyWindow(1)
-- Supply tab is 0 // Provisioning tab is 1 // Expert Delivery is 2
-- Anything above or below those numbers will not work
--
-- All it does is open the gc supply window to whatever tab you want, or changes to a tab if it's already open
function OpenGcSupplyWindow(tab)
    -- swaps tabs if the gc supply list is already open
    if IsAddonVisible("GrandCompanySupplyList") then
        if (tab <= 0 or tab >= 3) then
            Echo("Invalid tab number")
        else
            yield("/pcall GrandCompanySupplyList true 0 " .. tab)
        end
    elseif not IsAddonVisible("GrandCompanySupplyList") then
        -- Mapping for GetPlayerGC()
        local gc_officer_names = {
            [1] = "Storm Personnel Officer",
            [2] = "Serpent Personnel Officer",
            [3] = "Flame Personnel Officer"
        }

        local gc_id = GetPlayerGC()
        local gc_target = gc_officer_names[gc_id]

        if gc_target then
            -- Target the correct GC officer
            Target(gc_target)
            yield("/lockon")
        else
            Echo("Unknown Grand Company ID: " .. tostring(gc_id))
            return
        end


        repeat
            yield("/pint")
            Sleep(0.1)
        until IsAddonReady("SelectString")

        yield("/pcall SelectString true 0")

        repeat
            Sleep(0.1)
        until IsAddonReady("GrandCompanySupplyList")

        yield("/pcall GrandCompanySupplyList true 0 " .. tab)
    end
end

-- Usage: CloseGcSupplyWindow()
-- literally just closes the gc supply window
-- probably is due some small consistency changes but it should be fine where it is now
function CloseGcSupplyWindow()
    attempt_counter = 0
    ::tryagain::
    if IsAddonVisible("GrandCompanySupplyList") then
        yield("/pcall GrandCompanySupplyList true -1")

        repeat
            Sleep(0.1)
        until IsAddonReady("SelectString")

        yield("/pcall SelectString true -1")
    end
    if IsAddonReady("SelectString") then
        yield("/pcall SelectString true -1")
    end
    repeat
        attempt_counter = attempt_counter + 1
        Sleep(0.1)
    until not IsAddonVisible("GrandCompanySupplyList") and not IsAddonVisible("SelectString") or attempt_counter >= 50
    if attempt_counter >= 50 then
        Echo("Window still open, trying again")
        goto tryagain
    end
end

-- Usage: GcProvisioningDeliver()
--
-- Attempts to deliver everything under the provisioning window, skipping over what it can't
function GcProvisioningDeliver()
    Sleep(0.5)

    if HasPlugin("YesAlready") then
        PauseYesAlready()
    end

    for i = 4, 2, -1 do
        repeat
            Sleep(0.1)
        until IsAddonReady("GrandCompanySupplyList")
        local item_name = GetNodeText("GrandCompanySupplyList", 6, i, 10)
        local item_qty = tonumber(GetNodeText("GrandCompanySupplyList", 6, i, 6))
        local item_requested_amount = tonumber(GetNodeText("GrandCompanySupplyList", 6, i, 9))

        if ContainsLetters(item_name) and item_qty >= item_requested_amount then
            -- continue
        else
            LogInfo("[VAC] Nothing here, moving on")
            goto skip
        end

        local row_to_call = i - 2
        yield("/pcall GrandCompanySupplyList true 1 " .. row_to_call)
        local err_counter_request = 0
        local err_counter_supply = 0

        repeat
            err_counter_request = err_counter_request + 1
            Sleep(0.1)
        until IsAddonReady("GrandCompanySupplyReward") or err_counter_request >= 70

        if err_counter_request >= 70 then
            LogInfo("[VAC] Something might have gone wrong")
            err_counter_request = 0
        else
            yield("/pcall GrandCompanySupplyReward true 0")
        end

        Sleep(0.2)

        -- Wait for either SelectYesno or GrandCompanySupplyList
        local wait_time = 0
        local max_wait_time = 2.0 -- Max wait time

        while wait_time < max_wait_time do
            if IsAddonReady("SelectYesno") then
                -- SelectYesno appeared before GrandCompanySupplyList
                local attempt_count = 0
                local max_attempts = 10

                repeat
                    yield("/pcall SelectYesno true 0")
                    Sleep(0.05)

                    if IsAddonVisible("SelectYesno") then
                        attempt_count = attempt_count + 1
                    else
                        break
                    end
                until not IsAddonVisible("SelectYesno") or attempt_count >= max_attempts
                break
            elseif IsAddonReady("GrandCompanySupplyList") then
                -- GrandCompanySupplyList appeared first instead, SelectYesno was skipped
                break
            end

            Sleep(0.1)
            wait_time = wait_time + 0.1
        end

        repeat
            err_counter_supply = err_counter_supply + 1
            Sleep(0.1)
        until IsAddonReady("GrandCompanySupplyList") or err_counter_supply >= 50

        err_counter_supply = 0
        ::skip::
    end

    if HasPlugin("YesAlready") then
        RestoreYesAlready()
    end
end

-- Usage: FindWorldByID(11) // FindWorldByID(GetHomeWorld())
--
-- Looks through the World_ID_List for the world name with X id and returns the name
function FindWorldByID(searchID)
    for name, data in pairs(World_ID_List) do
        if data.ID == searchID then
            return name, data
        end
    end
    return nil, nil
end

-- Usage: FindDCWorldIsOn("Cerbeus") Will return Chaos
--
-- Looks through the DC_With_Worlds table and returns the datacenter a world is on
function FindDCWorldIsOn(worldName)
    for datacenter, worlds in pairs(DC_With_Worlds) do
        for _, world in ipairs(worlds) do
            if world == worldName then
                return datacenter
            end
        end
    end
    return nil
end

-- Usage: FindDutyID("Sastasha")
--
-- returns the id of the duty you search for, if the search is vague enough it'll return any of the ones that it finds, so try to be specific
function FindDutyID(duty_name)
    -- this needs to be here to replace funky dashes since square is funny
    local function replaceDashes(s)
        return s:gsub("–", "-"):gsub("—", "-"):gsub("‑", "-"):gsub("‐", "-")
    end
    local duty_name_lower = replaceDashes(string.lower(duty_name))
    for key, value in pairs(Zone_List) do
        local duty_value_lower = replaceDashes(string.lower(value["Duty"]))

        if duty_value_lower == duty_name_lower then
            return key
        end
    end

    return nil
end




-- Usage: FindZoneID("Limsa Lominsa Lower Decks")
--
-- returns the id of the zone you search for, if the search is vague enough it'll return any of the ones that it finds, so try to be specific
function FindZoneID(zone)
    zone = zone or Zone_List["" .. GetZoneID() .. ""]["Zone"]

    -- Check if zone is string
    if type(zone) ~= "string" then
        return nil -- return 0
    end

    local searchLower = zone:lower()

    for id, entry in pairs(Zone_List) do
        local placeName = entry["Zone"]
        if placeName and placeName:lower():find(searchLower) then
            return tonumber(id)
        end
    end

    return nil -- return 0
end

-- Usage: FindZoneIDByAetheryte("Limsa Lominsa Lower Decks")
--
-- returns the id of the zone of the aetheryte you search for, if the search is vague enough it'll return any of the ones that it finds, so try to be specific
function FindZoneIDByAetheryte(targetAetheryte)
    if type(targetAetheryte) ~= "string" then
        return nil
    end

    local lowerTarget = targetAetheryte:lower()

    for key, value in pairs(Zone_List) do
        if type(value) == "table" and type(value["Aetherytes"]) == "table" then
            for _, aetheryte in ipairs(value["Aetherytes"]) do
                if type(aetheryte) == "table" and type(aetheryte["Name"]) == "string" then
                    if aetheryte["Name"]:lower():find(lowerTarget, 1, true) then
                        return tonumber(key), aetheryte
                    end
                end
            end
        end
    end

    return nil, "Not found"
end

-- Function to find the name of an aetheryte by ID
-- Usage: local name = FindAetheryteNameByID("55")
-- 
-- Will return the name of the aetheryte with the given id, or nil if not found
function FindAetheryteNameByID(aetheryte_id)
    aetheryte_id = tonumber(aetheryte_id) -- make sure the id is a number
    for _, zone in pairs(Zone_List) do -- iterate over the zone list
        if zone["Aetherytes"] then -- checks if the aetheryte section is present
            for _, aetheryte in ipairs(zone["Aetherytes"]) do -- iterates over each aetheryte inside the zone
                if tonumber(aetheryte["ID"]) == aetheryte_id then -- converts the aetheryte id to number and checks it against the provided id
                    return aetheryte["Name"] -- returns the correct aetheryte name
                end
            end
        end
    end
    return nil  -- Return nil if not found
end


-- Function to find the ID of an aetheryte by name
-- Usage: local id = FindAetheryteIDByName("Aleport")
-- 
-- Will return the ID of the aetheryte with the given name, or nil if not found
function FindAetheryteIDByName(aetheryte_name)
    aetheryte_name = tostring(aetheryte_name):lower()  -- Convert input name to lower case
    for _, zone in pairs(Zone_List) do -- iterate over the zone list
        if zone["Aetherytes"] then -- checks if the aetheryte section is present
            for _, aetheryte in ipairs(zone["Aetherytes"]) do -- iterates over each aetheryte inside the zone
                if aetheryte["Name"]:lower() == aetheryte_name then  -- converts aetheryte name to lower case and checks it against the provided name
                    return tonumber(aetheryte["ID"]) -- returns the correct aetheryte id
                end
            end
        end
    end
    return nil     -- Return nil if not found
end

-- Usage: ContainsLetters("meow")
--
-- Will return if whatever you provide it has letters or not
function ContainsLetters(input)
    if input:match("%a") then
        return true
    else
        return false
    end
end

-- Usage: Distance(-96.71, 18.60, 0.50, -88.33, 18.60, -10.48) or anything that gives you an x y z pos value
-- Used to calculate the distance between two sets of x y z coordinates
-- Euclidean Distance
function Distance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx ^ 2 + dy ^ 2 + dz ^ 2)
end

-- Usage: DistanceName("First Last", "First Last") or DistanceName("Aetheryte", "Retainer Bell")
-- Used to calculate the distance between two object names
-- Euclidean Distance
function DistanceName(distance_char_name1, distance_char_name2)
    local x1 = GetObjectRawXPos(distance_char_name1)
    local y1 = GetObjectRawYPos(distance_char_name1)
    local z1 = GetObjectRawZPos(distance_char_name1)

    local x2 = GetObjectRawXPos(distance_char_name2)
    local y2 = GetObjectRawYPos(distance_char_name2)
    local z2 = GetObjectRawZPos(distance_char_name2)

    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx ^ 2 + dy ^ 2 + dz ^ 2)
end

-- Usage: PathToObject("First Last") or PathToObject("Aetheryte", 2)
-- Finds specified object and paths to it
-- Optionally can include a range value to stop once distance between character and target has been reached
function PathToObject(path_object_name, range)
    -- Check whether path_object_name isn't nil
    if not path_object_name or path_object_name == "" then
        LogInfo("[VAC] PathToObject name is empty.")
        Echo("PathToObject name is empty.")
        return
    end

    path_object_name = string.lower(path_object_name)

    if not DoesObjectExist(path_object_name) then
        LogInfo("[VAC] Object '" .. path_object_name .. "' does not exist.")
        Echo("Object '" .. path_object_name .. "' does not exist.")
        return
    end

    -- Get the object pos
    local x_pos = GetObjectRawXPos(path_object_name)
    local y_pos = GetObjectRawYPos(path_object_name)
    local z_pos = GetObjectRawZPos(path_object_name)

    -- Pass x y z pos to Movement, range optional
    if range then
        Movement(x_pos, y_pos, z_pos, range)
    else
        Movement(x_pos, y_pos, z_pos)
    end

    -- Wait until the pathing is complete
    repeat
        Sleep(0.1)
    until not PathIsRunning()
end

-- Finds where your estate entrance is and paths to it
-- I think this will break though since there will be multiple entrances around a housing area
-- So maybe needs nearest logic
function PathToEstateEntrance()
    Movement(GetObjectRawXPos("Entrance"), GetObjectRawYPos("Entrance"), GetObjectRawZPos("Entrance"), 4)
end

-- Function to navigate to the summoning bell in limsa lominsa lower decks
-- Usage: PathToLimsaBell()
--
-- Will move the character to the summoning bell if already in limsa lominsa lower decks,
-- Otherwise teleports to limsa lominsa and then moves to the summoning bell
function PathToLimsaBell()
    -- Check if the current zone is limsa lominsa lower decks
    if ZoneCheck("Limsa Lominsa Lower Decks") then
        -- Move directly to the summoning bell using its coordinates
        Movement(GetObjectRawXPos("Summoning Bell"), GetObjectRawYPos("Summoning Bell"),
            GetObjectRawZPos("Summoning Bell"))
    else
        -- Teleport to limsa lominsa if not already in lower decks
        Teleporter("Limsa Lominsa", "tp")
        -- After teleporting, move to the summoning bell using its coordinates
        Movement(GetObjectRawXPos("Summoning Bell"), GetObjectRawYPos("Summoning Bell"),
            GetObjectRawZPos("Summoning Bell"))
    end
end

-- Function to wait until a specified amount of gil is traded
-- Usage: WaitForGilIncrease(1)
--
-- This function monitors the gil amount and waits until it increases by the
-- specified amount. It acts as a trigger before proceeding with further actions.
function WaitForGilIncrease(gil_increase_amount)
    -- Store the current amount of gil before the trade
    local previous_gil = GetGil()

    -- Continuously check the gil amount until the specified increase is detected
    while true do
        Sleep(1.0) -- Pause execution for 1 second between checks

        -- Retrieve the current amount of gil
        local current_gil = GetGil()

        -- Check if the gil has increased by the specified amount
        if current_gil > previous_gil and (current_gil - previous_gil) == gil_increase_amount then
            Echo(gil_increase_amount .. " Gil successfully traded")
            break -- Exit the loop when the desired increase in gil is detected
        end

        -- Update the previous gil amount for the next check
        previous_gil = current_gil
    end
end

-- Usage: PartyInvite("First Last")
-- Will target and invite player to a party, and retrying if the invite timeout happens
-- Can only be used if target is in range
function PartyInvite(party_invite_name)
    local invite_timeout = 305   -- 300 Seconds is the invite timeout, adding 5 seconds for good measure
    local start_time = os.time() -- Stores the invite time

    while not IsInParty() do
        repeat
            Sleep(0.1)
        until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

        Target(party_invite_name)
        yield("/invite")

        -- Wait for the target player to accept the invite or the timeout to expire
        while not IsInParty() do
            Sleep(0.1)

            -- Check if the invite has expired
            if os.time() - start_time >= invite_timeout then
                Echo("Invite expired. Reinviting " .. party_invite_name)
                start_time = os.time() -- Reset the start time for the new invite
                break                  -- Break the loop to resend the invite
            end
        end
    end
    -- stuff could go here
end

-- Usage: PartyInviteMenu("First", "First Last")
-- Will invite player to a party through the social menu, and retrying if the invite timeout happens
-- Can be used from anywhere
-- Semi broken at the moment
function PartyInviteMenu(party_invite_menu_first, party_invite_menu_full)
    local invite_timeout = 305   -- 300 Seconds is the invite timeout, adding 5 seconds for good measure
    local start_time = os.time() -- Stores the invite time

    while not IsInParty() do
        repeat
            Sleep(0.1)
        until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

        repeat
            yield('/search first "' .. party_invite_menu_first .. '" en jp de fr')
            Sleep(0.5)
        until IsAddonVisible("SocialList")

        -- Probably needs the node scanner here to match the name, otherwise it will invite whoever was previously searched, will probably mess up for multiple matches too

        repeat
            yield('/pcall SocialList true 1 0 "' .. party_invite_menu_full .. '"')
            Sleep(0.5)
        until IsAddonVisible("ContextMenu")

        repeat
            yield("/pcall ContextMenu true 0 3 0")
            Sleep(0.1)
        until not IsAddonVisible("ContextMenu")

        repeat
            yield("/pcall Social true -1")
            Sleep(0.1)
        until not IsAddonVisible("Social")

        -- Wait for the target player to accept the invite or the timeout to expire
        while not IsInParty() do
            Sleep(0.1)

            -- Check if the invite has expired
            if os.time() - start_time >= invite_timeout then
                Echo("Invite expired. Reinviting " .. party_invite_menu_full)
                start_time = os.time() -- Reset the start time for the new invite
                break                  -- Break the loop to resend the invite
            end
        end
    end
    -- stuff could go here
end

-- Usage: PartyDisband()
-- Will check if player is in party and disband party
function PartyDisband()
    if IsInParty() then
        repeat
            Sleep(0.1)
        until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

        yield("/partycmd disband")

        repeat
            yield("/pcall SelectYesno true 0")
            Sleep(0.1)
        until not IsAddonVisible("SelectYesno")
    end
end

-- Usage: PartyAccept()
-- Will accept party invite if not in party
-- NEEDS a name arg
function PartyAccept()
    if not IsInParty() then
        -- Wait until the player is available, not casting, and not in combat
        repeat
            Sleep(0.1)
        until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

        -- Wait until the "SelectYesno" addon is visible
        repeat
            Sleep(0.1)
        until IsAddonVisible("SelectYesno")

        Sleep(0.1)

        -- Accept the party invite
        yield("/pcall SelectYesno true 0")

        -- Wait until the player is in a party
        repeat
            Sleep(0.1)
        until IsInParty()

        LogInfo("[VAC] Party invitation accepted.")
    else
        LogInfo("[VAC] Player is already in a party.")
    end
end

-- Usage: PartyLeave()
-- Will leave party if in a party
function PartyLeave()
    if IsInParty() then
        repeat
            Sleep(0.1)
        until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

        yield("/partycmd leave")

        repeat
            Sleep(0.1)
        until IsAddonVisible("SelectYesno")

        Sleep(0.1)

        repeat
            yield("/pcall SelectYesno true 0")
            Sleep(0.1)
        until not IsAddonVisible("SelectYesno")

        LogInfo("[VAC] Party has been left.")
    else
        LogInfo("[VAC] Player is not in a party.")
    end
end

-- Usage: EstateTeleport("First Last", 0)
-- Options: 0 = Free Company, 1 = Personal, 2 = Apartment
-- Opens estate list of added friend and teleports to specified location
-- ZoneTransitions() not required to be called after
function EstateTeleport(estate_char_name, estate_type)
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

    yield("/estatelist " .. estate_char_name)

    repeat
        yield("/pcall TeleportHousingFriend true " .. estate_type)
        Sleep(0.1)
    until not IsAddonVisible("TeleportHousingFriend")

    ZoneTransitions()
end

-- Usage: RelogCharacter("First Last@Server")
-- Relogs specified character, should be followed with a LoginCheck()
-- Requires @Server else it will not work
-- Requires Auto Retainer plugin
function RelogCharacter(relog_char_name)
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

    yield("/ays relog " .. relog_char_name)
end

-- Usage: EquipRecommendedGear()
-- Equips recommended gear if any available
function EquipRecommendedGear()
    LogInfo("[VAC] Equipping recommended gear")
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

    repeat
        yield("/character")
        Sleep(0.1)
    until IsAddonVisible("Character")

    repeat
        yield("/pcall Character true 12")
        Sleep(0.1)
    until IsAddonVisible("RecommendEquip")

    repeat
        yield("/character")
        Sleep(0.1)
    until not IsAddonVisible("Character")

    repeat
        yield("/pcall RecommendEquip true 0")
        Sleep(0.1)
    until not IsAddonVisible("RecommendEquip")
end

-- Usage: WaitUntilObjectExists("First Last") or WaitUntilObjectExists("Aetheryte")
-- Checks if specified object exists near to your character
function WaitUntilObjectExists(object_name)
    repeat
        Sleep(0.1)
    until DoesObjectExist(object_name)
end

-- Usage: GetRandomNumber(1.5, 3.5) or GetRandomNumber(2, 4)
-- Allows for variance in values such as differing Sleep() wait times
function GetRandomNumber(min, max)
    -- Reseed the random number
    math.randomseed(os.time() + os.clock() * 100000)

    -- Generate and return a random number from the min and max values
    return min + (max - min) * math.random()
end

-- Usage: GetPlayerPos()
-- Finds and returns player x, y, z pos
function GetPlayerPos() 
    -- Find and format player pos
    local x, y, z = GetPlayerRawXPos(), GetPlayerRawYPos(), GetPlayerRawZPos()
    local pos = string.format("%.2f, %.2f, %.2f", x, y, z)

    return pos
end

-- Usage: GetPlayerJob()
-- Returns the current player job abbreviation, or pass true if you want the full name
function GetPlayerJob(boolean)
    -- Mapping for GetClassJobId()
    -- Find and return job ID
    local job_id = GetClassJobId()
    -- check if true has been passed
    if boolean == true then
        -- returns the full name of the job
        return Job_List[job_id]["Name"] or "Unknown job"
    else
        -- returns the job abbreviation
        return Job_List[job_id]["Abbreviation"] or "Unknown job"
    end
end

-- Usage: DoAction("Heavy Shot")
-- Uses specified action
function DoAction(action_name)
    if GetCharacterCondition(4) then
        repeat
            Dismount()
            Sleep(0.1)
        until not GetCharacterCondition(4)
    end

    yield('/ac "' .. action_name .. '"')
end

-- Usage: DoGeneralAction("Jump")
-- Uses specified general action
function DoGeneralAction(general_action_name)
    -- Check if the action is not "Jump" and the character is mounted
    if general_action_name ~= "Jump" and GetCharacterCondition(4) then
        repeat
            Dismount()
            Sleep(0.1)
        until not GetCharacterCondition(4)
    end

    -- Do the general action
    yield('/gaction "' .. general_action_name .. '"')
end

-- Usage: DoTargetLockon()
-- Locks on to current target
function DoTargetLockon(target_lockon_name)
    yield("/lockon")
end

-- Usage: IsQuestDone("Hello Halatali")
-- Checks if you have completed the specified quest
function IsQuestDone(quest_done_name)
    if not quest_done_name or quest_done_name == "" then
        return nil -- Return nil if the quest_done_name is nil or an empty string
    end

    -- Initialize a variable to store the quest_key
    local quest_key = nil

    -- Search for the quest in Quest_List by name
    for key, quest in pairs(Quest_List) do
        if string.lower(quest['Name']) == string.lower(quest_done_name) then
            quest_key = tonumber(key)
            break
        end
    end

    -- If the quest is found, check if it is complete
    if quest_key then
        return IsQuestComplete(tonumber(quest_key))
    end

    -- Return false if the quest is not found or not completed
    return false
end

-- Usage: DoQuest("Hallo Halatali") or DoQuest(1433)
-- Checks if you have completed the specified quest and starts if you have not
function DoQuest(quest_do_name)

    -- If input is nil or an empty string
    if not quest_do_name or quest_do_name == "" then
        LogInfo("[VAC] (DoQuest) quest_do_name is nil or an empty string")
        return nil -- Return nil if the quest_do_name is nil or an empty string
    end

    -- Initialize variables to store quest information
    local quest_key = nil
    local quest_id = nil

    -- check if quest id was already provided by user directly
    if type(quest_do_name) == "number" then
        quest_id = quest_do_name
    else
        quest_id = nil
    end

    -- Search for the quest in Quest_List by name
    if not quest_id then
        for key, quest in pairs(Quest_List) do
            if string.lower(quest['Name']) == string.lower(quest_do_name) and (string.lower(quest['ClassJobUnlock']) == string.lower(GetPlayerJob(true)) or string.lower(quest['ClassJobUnlock'])) == string.lower("adventurer") then
                quest_id = tonumber(quest['ID'])
                Echo(quest_id)
                quest_key = tonumber(key)
                break
            end
        end
    else
    -- Search for the quest key by quest_id instead since quest_id was provided by user
        for key, quest in pairs(Quest_List) do
            if tonumber(quest['ID']) == quest_do_name then
                quest_key = tonumber(key)
                break
            end
        end
    end

    -- If the quest is not found, echo and return false
    if not quest_id or not quest_key then
        LogInfo('[VAC] (DoQuest) Quest "' .. quest_do_name .. '" not found.')
        Echo('Quest "' .. quest_do_name .. '" not found.')
        return false
    end

    -- Check if the quest is already completed
    if IsQuestComplete(tonumber(quest_key)) then
        LogInfo('[VAC] (DoQuest) You have already completed the "' .. quest_do_name .. '" quest.')
        Echo('You have already completed the "' .. quest_do_name .. '" quest.')
        return true
    end

    -- Ensure the player is available and not in the middle of zone transition before starting the quest
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26) and not (GetCharacterCondition(45) or GetCharacterCondition(51))

    -- Readies the quest
    yield("/qst next " .. quest_id)

    -- Wait for player availability again after quest initiation, also acts as a small sleep
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

    -- Start the quest
    yield("/qst start")
    
    -- Ensure Questionable is running before checking for stuck issues
    repeat
        Sleep(0.1)
    until QuestionableIsRunning() -- Wait for quest to fully start

    -- Initialize stuck checker variables
    local stuck_check_interval = 0.50   -- Time between stuck checks
    local stuck_threshold_seconds = 4.0 -- Time before considering stuck
    local min_progress_distance = 0.1   -- Minimum distance to be considered as progress

    local stuck_timer = 0
    local previous_position = {
        x = GetPlayerRawXPos(),
        y = GetPlayerRawYPos(),
        z = GetPlayerRawZPos()
    }

    -- Function to handle stuck checks
    local function CheckIfStuck()
        -- Loop continuously while the quest is incomplete
        while not IsQuestComplete(tonumber(quest_key)) do
            Sleep(stuck_check_interval)

            -- If player is busy or in a zone transition, reset the stuck timer and skip
            if not IsPlayerAvailable() or IsPlayerCasting() or GetCharacterCondition(26) or GetCharacterCondition(32) then
                stuck_timer = 0 -- Reset stuck timer
                previous_position = { -- Reset position for next check
                    x = GetPlayerRawXPos(),
                    y = GetPlayerRawYPos(),
                    z = GetPlayerRawZPos()
                }
                -- Wait for the player to be available again
                repeat
                    Sleep(0.1)
                until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26) and not GetCharacterCondition(32) and not (GetCharacterCondition(31) or GetCharacterCondition(32))
            end

            -- Handle zone transitions
            if GetCharacterCondition(45) or GetCharacterCondition(51) then
                previous_position = { -- Reset position tracking
                    x = GetPlayerRawXPos(),
                    y = GetPlayerRawYPos(),
                    z = GetPlayerRawZPos()
                }
                stuck_timer = 0 -- Reset stuck timer

                -- Wait until the player finishes zoning
                repeat
                    Sleep(0.1)
                until not GetCharacterCondition(45) and not GetCharacterCondition(51)

                -- After zoning, reload navmesh and questionable
                NavReload()
                
                -- Check if the quest has been accepted and reloads, otherwise it will loop forever
                if IsQuestNameAccepted(quest_do_name) then
                    yield("/qst reload")
                else
                    -- Retry quest start if it hasn't been accepted yet
                    yield("/qst next " .. quest_id)
                    
                    repeat
                        Sleep(0.1)
                    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)
                    
                    yield("/qst start")
                end
            end

            -- Calculate player's movement since last check
            local current_position = {
                x = GetPlayerRawXPos(),
                y = GetPlayerRawYPos(),
                z = GetPlayerRawZPos()
            }
            local dx = current_position.x - previous_position.x
            local dy = current_position.y - previous_position.y
            local dz = current_position.z - previous_position.z
            local distance_moved_squared = dx * dx + dy * dy + dz * dz

            -- If the player hasn't moved far enough, increase the stuck timer
            if distance_moved_squared < min_progress_distance * min_progress_distance then
                stuck_timer = stuck_timer + stuck_check_interval
            else
                stuck_timer = 0 -- Reset stuck timer if progress is made
            end

            -- If stuck for too long, attempt to resolve by jumping and reloading quest data
            if stuck_timer >= stuck_threshold_seconds then
                DoGeneralAction("Jump") -- Try jumping to get unstuck
                Sleep(0.1)
                NavReload() -- Reload Navmesh
                
                -- Check if the quest has been accepted, otherwise it will loop forever
                if IsQuestNameAccepted(quest_do_name) then
                    NavReload() -- Reload Navmesh
                    yield("/qst reload") -- Reload quest data
                else
                    -- If the quest hasn't been accepted, retry quest start
                    yield("/qst next " .. quest_id)
                    repeat
                        Sleep(0.1)
                    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)
                    yield("/qst start")
                end

                -- Wait until navigation and quest are ready
                repeat
                    Sleep(0.05)
                until NavIsReady() or QuestionableIsRunning()

                stuck_timer = 0 -- Reset stuck timer after reloading
            end

            -- Update the previous position for the next check
            previous_position = current_position
        end
    end

    -- Run the stuck checker while waiting for the quest to complete
    while not IsQuestComplete(tonumber(quest_key)) do
        Sleep(0.1)

        -- Check if the player is available and not busy before running the stuck checker
        if IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26) and not GetCharacterCondition(32) then
            CheckIfStuck() -- Run the stuck checker
        end
    end

    -- Ensure the quest is fully completed before ending
    Sleep(0.5)

    -- Clear the quest values after completion
    quest_id = nil
    quest_key = nil

    return true
end

-- Usage: IsPlayerLowerThanLevel(100)
-- Checks if player level lower than specified amount, returns true if so
function IsPlayerLowerThanLevel(player_lower_level)
    if GetLevel() < player_lower_level then
        return true
    end
end

-- Usage: IsPlayerHigherThanLevel(1)
-- Checks if player level higher than specified amount, returns true if so
function IsPlayerHigherThanLevel(player_higher_level)
    if GetLevel() > player_higher_level then
        return true
    end
end

-- Usage: AutoDutyRun("Sastasha")
-- 
-- Runs a dungeon once through AutoDuty
function AutoDutyRun(duty)
    duty = tostring(duty)
    local duty_id = FindDutyID(duty)
    yield("/autoduty run support " .. duty_id .. " 1")
end

-- NEEDS some kind of translation so you can just do "Sastasha" than needing to do 1
-- NEEDS fixing as character with fewer dungeons have different duty_finder_number
-- Usage: DutyFinderQueue for "Sastasha"
-- Options: 0-9 for duty tab, 1-999 for duty number
-- Automatically queues for specified duty, waits until player has exited duty
function DutyFinderQueue(duty_finder_tab_number, duty_finder_number)
    -- Open duty finder
    repeat
        yield("/dutyfinder")
        Sleep(0.1)
    until IsAddonVisible("ContentsFinder")

    -- Pick the duty tab
    repeat
        yield("/pcall ContentsFinder true 1 " .. duty_finder_tab_number)
        Sleep(0.1)
    until IsAddonVisible("JournalDetail")

    -- Clear the duty selection
    repeat
        yield("/pcall ContentsFinder true 12 1")
        Sleep(0.1)
    until IsAddonVisible("ContentsFinder")

    -- Pick the duty
    repeat
        yield("/pcall ContentsFinder true 3 " .. duty_finder_number)
        Sleep(0.1)
    until IsAddonVisible("ContentsFinder")

    -- Take note of current ZoneID to know when duty is over later
    Sleep(0.1)
    local current_zone_id = GetZoneID()

    -- Queue the duty
    repeat
        yield("/pcall ContentsFinder true 12 0")
        Sleep(0.1)
    until IsAddonVisible("ContentsFinderConfirm")

    -- Accept the duty
    repeat
        yield("/pcall ContentsFinderConfirm true 8")
        Sleep(0.1)
    until not IsAddonVisible("ContentsFinderConfirm")

    -- Compare ZoneID to know when duty is over
    Sleep(5.0)
    if GetZoneID() ~= current_zone_id then
        repeat
            ZoneCheck(GetZoneID())
            Sleep(0.1)
        until current_zone_id == GetZoneID()
    end
end

-- NEEDS some kind of translation so you can just do "Sastasha" than needing to do 1
-- NEEDS fixing as character with fewer dungeons have different duty_finder_number
-- Usage: DutyFinderQueue(5) for "The Aurum Vale" OpenRegularDuty(5)
-- Options: 0-9 for duty tab, 1-999 for duty number
-- Automatically queues for specified duty, waits until player has exited duty

-- will return to this later

-- function DutyFinderQueue(duty_finder_number, duty_finder_name)
-- -- Open duty finder
-- repeat
-- yield("/dutyfinder")
-- Sleep(0.1)
-- until IsAddonVisible("ContentsFinder")

-- -- Clear the duty selection
-- repeat
-- yield("/pcall ContentsFinder true 12 1")
-- Sleep(0.1)
-- until IsAddonVisible("ContentsFinder")

-- -- Pick the duty
-- repeat
-- OpenRegularDuty(duty_finder_number)
-- Sleep(0.1)
-- until IsAddonVisible("ContentsFinder")

-- -- Take note of current ZoneID to know when duty is over later
-- Sleep(0.1)
-- local current_zone_id = GetZoneID()

-- -- Queue the duty
-- repeat
-- yield("/pcall ContentsFinder true 12 0")
-- Sleep(0.1)
-- until IsAddonVisible("ContentsFinderConfirm")

-- -- Accept the duty
-- repeat
-- yield("/pcall ContentsFinderConfirm true 8")
-- Sleep(0.1)
-- until not IsAddonVisible("ContentsFinderConfirm")

-- -- Compare ZoneID to know when duty is over
-- Sleep(5.0)
-- if GetZoneID() ~= current_zone_id then
-- repeat
-- ZoneCheck(GetZoneID())
-- Sleep(0.1)
-- until current_zone_id == GetZoneID()
-- end
-- end

-- NEEDS loot rules and language fixing
-- Usage: DutyFinderSettings(0, 1, 2, 6) or DutyFinderSettings(0, 1)
-- Options: 0-8 for duty settings
-- 0 = Join Party in progress
-- 1 = Unrestricted Party
-- 2 = Level Sync (Requires Unrestricted Party)
-- 3 = Minimum IL
-- 4 = Silence Echo
-- 5 = Explorer Mode
-- 6 = Limited Leveling Roulette
-- 7 = Loot Rules (Normal, Greed Only, Lootmaster)
-- 8 = Language (Jp, En, De, Fr)
-- Automatically sets specified duty finder settings
function DutyFinderSettings(...)
    local duty_finder_settings = { ... }

    -- Open duty finder
    repeat
        yield("/dutyfinder")
        Sleep(0.1)
    until IsAddonVisible("ContentsFinder")

    -- Open duty finder settings
    repeat
        yield("/pcall ContentsFinder true 15")
        Sleep(0.1)
    until IsAddonVisible("ContentsFinderSetting")

    -- Loop through each setting and apply it
    for _, setting_number in ipairs(duty_finder_settings) do
        repeat
            yield("/pcall ContentsFinderSetting true 1 " .. setting_number .. " 1")
            Sleep(0.1)
        until IsAddonVisible("ContentsFinderSetting")
    end

    -- Close duty finder settings
    repeat
        yield("/pcall ContentsFinderSetting true 0")
        Sleep(0.1)
    until not IsAddonVisible("ContentsFinderSetting")
end

-- NEEDS loot rules and language fixing
-- Usage: DutyFinderSettingsClear()
-- Clear duty finder settings
function DutyFinderSettingsClear()
    -- Open duty finder
    repeat
        yield("/dutyfinder")
        Sleep(0.1)
    until IsAddonVisible("ContentsFinder")

    -- Open duty finder settings
    repeat
        yield("/pcall ContentsFinder true 15")
        Sleep(0.1)
    until IsAddonVisible("ContentsFinderSetting")

    -- Iterate through all settings (0-8) and clear them
    for setting_number = 0, 8 do
        repeat
            yield("/pcall ContentsFinderSetting true 1 " .. setting_number .. " 0")
            Sleep(0.1)
        until IsAddonVisible("ContentsFinderSetting")
    end

    -- Close duty finder settings
    repeat
        yield("/pcall ContentsFinderSetting true 0")
        Sleep(0.1)
    until not IsAddonVisible("ContentsFinderSetting")
end

-- Usage: Dismount()
-- Checks if player is mounted, dismounts if true
function Dismount()
    if TerritorySupportsMounting() then
        if GetCharacterCondition(4) then
            repeat
                yield("/mount")
                Sleep(0.1)
            until not GetCharacterCondition(4)
        end

        repeat
            Sleep(0.1)
        until IsPlayerAvailable() and not IsPlayerCasting()
    else
        -- do nothing
    end
end

-- Usage: DropboxSetAll() or DropboxSetAll(123456)
-- Sets all items in Dropbox plugin to max values
-- Optionally can include a numerical value to set gil transfer amount
function DropboxSetAll(dropbox_gil)
    if not Item_List then
        LogInfo("[VAC] Item_List is nil. Cannot set items.")
        return
    end
    
    -- Gil cap or specified gil amount
    local gil = dropbox_gil or 999999999
    
    -- Maximum quantity for items (999 * 140)
    local max_quantity = 139860
    
    -- Iterate over the Item_List
    for id, item in pairs(Item_List) do
        -- Check if the item is tradeable
        if not item['Untradeable'] then
            if id == 1 then
                -- Set gil to gil cap or specified gil amount
                DropboxSetItemQuantity(id, false, gil)
            elseif id < 2 or id > 19 then -- Excludes Shards, Crystals, and Clusters
                -- Set all item ID except 2-19
                DropboxSetItemQuantity(id, false, max_quantity) -- NQ
                DropboxSetItemQuantity(id, true, max_quantity)  -- HQ
            end
        end
    
        Sleep(0.0001)
    end
end

-- Usage: DropboxClearAll()
-- Clears all items in Dropbox plugin
function DropboxClearAll()
    if not Item_List then
        LogInfo("[VAC] Item_List is nil. Cannot clear items.")
        return
    end

    for id, item in pairs(Item_List) do
        if not item['Untradeable'] then
            DropboxSetItemQuantity(id, false, 0) -- NQ
            DropboxSetItemQuantity(id, true, 0)  -- HQ
        end
        Sleep(0.0001)
    end
end

-- Usage: IsQuestNameAccepted("Hello Halatali.")
-- Checks if quest name is accepted
function IsQuestNameAccepted(quest_accepted_name)
    if not quest_accepted_name or quest_accepted_name == "" then
        return nil -- Return nil if the quest_accepted_name is nil or an empty string
    end

    for key, entry in pairs(Quest_List) do
        if string.lower(entry['Name']) == string.lower(quest_accepted_name) then
            return IsQuestAccepted(tonumber(key))
        end
    end
    return nil -- Return nil if the name isn't found
end

-- Usage: IsHuntLogComplete(9, 0) or IsHuntLogComplete(0, 1)
-- Checks if player has the hunt log rank completed
-- Valid jobs: 0 = GLA, 1 = PGL, 2 = MRD, 3 = LNC, 4 = ARC, 5 = ROG, 6 = CNJ, 7 = THM, 8 = ACN, 9 = GC
-- Valid ranks/pages: 0-4 for jobs, 0-2 for GC
function IsHuntLogComplete(class, rank)
    OpenHuntLog(class, rank)
    local rank_text = GetNodeText("MonsterNote", 33, rank, 3)
    local left_num, right_num = rank_text:match("([^/]+)/([^/]+)")
    if left_num == right_num then
        CloseHuntLog()
        return true
    else
        CloseHuntLog()
        return false
    end
end

-- Usage: GetPlayerJobLevel() // GetPlayerJobLevel("WAR") // GetPlayerJobLevel(11)
-- Returns current player job level, can specify job to check, even id if you really want to be cursed
function GetPlayerJobLevel(job)
    local job = job or GetClassJobId()
    if type(job) == "string" then
        local function findJobXPByAbbreviation(abbreviation)
            for index, job in ipairs(Job_List) do
                if job["Abbreviation"] == abbreviation then
                    return tonumber(GetLevel(job["ExpArrayIndex"]))
                end
            end
            return "Unknown job"
        end
        return findJobXPByAbbreviation(job) or "Unknown job"
    elseif type(job) ~= nil then
        return tonumber(GetLevel(Job_List[job]["ExpArrayIndex"]))
    end
end

-- Usage: ReturnHomeWorld()
-- Checks if player is not on home world and returns Home
-- ZoneTransitions() not required to be called after
function ReturnHomeWorld()
    local homeworld = FindWorldByID(GetHomeWorld())
    Echo("Attempting to return to " .. homeworld)

    if GetCurrentWorld() ~= GetHomeWorld() then
        Teleporter(homeworld, "li")
    end

    repeat
        Sleep(0.1)
    until GetCurrentWorld() == GetHomeWorld() and IsPlayerAvailable() and not LifestreamIsBusy()
end

-- Usage: CheckPluginsEnabled("AutoRetainer") or CheckPluginsEnabled("AutoRetainer", "TeleporterPlugin", "Lifestream")
-- Can take an infinite amount of plugin strings
-- Will check if the player has the specified plugins installed/enabled and echoes enabled + disabled plugins
-- If statement can be used
function CheckPluginsEnabled(...)
    local enabled_plugins = {}
    local missing_plugins = {}

    -- Pass all arguments into a table
    local plugins = { ... }

    for _, plugin_name in ipairs(plugins) do
        if HasPlugin(plugin_name) then
            table.insert(enabled_plugins, plugin_name)
        else
            table.insert(missing_plugins, plugin_name)
        end
    end

    -- Sort the plugin names a-z
    table.sort(enabled_plugins)
    table.sort(missing_plugins)

    -- Echo enabled plugins
    if #enabled_plugins > 0 then
        LogInfo("[VAC] Enabled plugins: " .. table.concat(enabled_plugins, ", "))
        Echo("Enabled plugins: " .. table.concat(enabled_plugins, ", "))
    else
        LogInfo("[VAC] No plugins are enabled.")
        Echo("No plugins are enabled.")
    end

    -- Echo missing plugins
    if #missing_plugins > 0 then
        LogInfo("[VAC] Missing or not enabled plugins: " .. table.concat(missing_plugins, ", "))
        Echo("Missing or not enabled plugins: " .. table.concat(missing_plugins, ", "))
        return false -- Returns false to be used with if statements to stop script
    else
        LogInfo("[VAC] All plugins are enabled.")
        Echo("All plugins are enabled.")
        return true -- Returns true be used with if statements to start script
    end
end

-- Usage: FindItemID("Copper")
--
-- Searches the item list for an item and returns it's id, not case sensitive but you need the full item name
function FindItemID(item_to_find)
    local searchTerm = string.lower(item_to_find)

    for key, item in pairs(Item_List) do
        local itemName = string.lower(item['Name'])

        if itemName == searchTerm then
            return key
        end
    end
    return nil
end

-- Usage: IsAetheryteAttuned("Limsa Lominsa")
-- Will check whether player has specified aetheryte attuned
-- Returns true or false
function IsAetheryteAttuned(aetheryte_attuned_name)
    -- Validate input
    if not aetheryte_attuned_name or aetheryte_attuned_name == "" then
        LogInfo("[VAC] IsAetheryteAttuned: Aetheryte name is missing or empty.")
        Echo("Aetheryte name is missing or empty.")
        return false
    end

    -- Convert the input name to lowercase
    local aetheryte_attuned_name = string.lower(aetheryte_attuned_name)

    -- Find the Aetheryte ID by name
    local aetheryte_id = FindAetheryteIDByName(aetheryte_attuned_name)
    
    -- If Aetheryte ID is not found
    if not aetheryte_id then
        LogInfo("[VAC] IsAetheryteAttuned: Aetheryte '" .. aetheryte_attuned_name .. "' not found.")
        Echo("Aetheryte '" .. aetheryte_attuned_name .. "' not found.")
        return false
    end

    -- Check if the Aetheryte is unlocked/attuned
    if IsAetheryteUnlocked(aetheryte_id) then
        return true
    else
        return false
    end
end

-- Usage: GetLocalTime()
-- Returns local time in HH:MM:SS format
function GetLocalTime()
    return os.date("%H:%M:%S")
end

-- Usage: GetServerTime()
-- Returns UTC time in HH:MM:SS format
function GetServerTime()
    return os.date("!%H:%M:%S")
end

-- Usage: GetEorzeanTime()
-- Returns Eorzean Time in HH:MM:SS format
function GetEorzeanTime()
    local eorzean_time = os.time() * 3600 / 175
    return string.format("%02d:%02d:%02d", 
        math.floor(eorzean_time / 3600) % 24, 
        math.floor(eorzean_time / 60) % 60, 
        math.floor(eorzean_time) % 60)
end

-- Usage: ReturnTeleport()
-- Uses /return action to return to aetheryte location
function ReturnTeleport()
    -- Initial check to ensure player can teleport
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26) and not GetCharacterCondition(32)

    yield("/return")
    
    repeat
        Sleep(0.1)
    until IsAddonVisible("SelectYesno")

    yield("/pcall SelectYesno true 0")

    repeat
        Sleep(0.1)
    until not IsAddonVisible("SelectYesno")

    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26)

    -- Wait for a zone transition to complete
    repeat
        Sleep(0.1)
    until GetCharacterCondition(45) or GetCharacterCondition(51)

    Sleep(0.5)
end

-- Usage: IsTeleportUnlocked()
-- Checks if player has teleport unlocked
function IsTeleportUnlocked()
    local aetheryte_list = GetAetheryteList()

    -- Check if aetheryte_list is nil, empty, or has a count less than 2
    if aetheryte_list and aetheryte_list.Count and aetheryte_list.Count >= 2 then
        return true
    else
        return false
    end
end

-- Usage: AttuneAethernetShard()
-- Attunes with the Aethernet Shard, exits out of menus if already attuned
function AttuneAethernetShard()
    -- Wait until the player is ready to interact
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not GetCharacterCondition(26) and not IsMoving() and not (GetCharacterCondition(45) or GetCharacterCondition(51))

    -- Target and interact with the Aethernet Shard
    Target("Aethernet Shard")
    Sleep(0.1)
    Interact()

    -- If the player is already attuned, exit the menu
    if (GetCharacterCondition(31) or GetCharacterCondition(32)) and IsAddonVisible("TelepotTown") then
        repeat
            Sleep(0.1)
        until IsAddonVisible("TelepotTown")

        Sleep(0.5)
        yield("/pcall TelepotTown true 1")

        -- Wait until the menu is no longer visible
        repeat
            Sleep(0.1)
        until not IsAddonVisible("TelepotTown")
    end

    -- Wait until player is available
    repeat
        Sleep(0.1)
    until IsPlayerAvailable() and not IsPlayerCasting() and not (GetCharacterCondition(31) or GetCharacterCondition(32))
    
    Sleep(1.0)
end

-- Usage: GetCharacterLevel()
-- Encapsulates the GetLevel() snd function with better handling
-- Returns the player level
function GetCharacterLevel()
    -- Check for conditions where the level might not be accessible due to changing zones
    if GetCharacterCondition(45) or GetCharacterCondition(51) then
        return nil -- Return nil if the player is changing zones
    end

    local player_level = GetLevel()

    -- Check if we have a number, if not return nil
    if type(player_level) ~= "number" then
        return nil
    end

    return player_level
end