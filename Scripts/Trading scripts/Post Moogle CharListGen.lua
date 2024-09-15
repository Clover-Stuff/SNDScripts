--[[

############################################################
##                       Post Moogle                      ##
##                 Character List Generator               ##
############################################################


####################
##    Version     ##
##     1.0.0      ##
####################

-> 1.0.0: Initial release

####################################################
##                  Description                   ##
####################################################

Generates a character list you can insert into vac_char_list for use with Post Moogle, or directly into Post Moogle itself

i almost recommend running this without much configuration and configuring everything on a per character basis

####################################################
##                Required Plugins                ##
####################################################

-> None

#####################
##    Settings     ##
###################]]
-- set the characters you're generating a list with, the list generates in order
-- you could technically just copy the character_list from the vac_char_list if you have one there into this

local gen_char_list = {
    "Mrow Mrow@Louisoux",
    "Smol Meow@Lich",
    "Beeg Meow@Zodiark",
}

-- Here you can define a list of trading partners.
-- If a partner is not provided (i.e., it remains empty), the default trading partner will be used, the one set in trading_with in the default settings section.
local trading_with_list = {
    --"Mrow Mrow@Louisoux",   -- Corresponding trading partner for Character 1
    --"Smol Meow@Lich",       -- Corresponding trading partner for Character 2
    --"Beeg Meow@Zodiark"     -- Corresponding trading partner for Character 3
}

-- Here you set the default settings each character will have when generated, you can just leave everything default and edit it on a per character basis after it's generated

local trading_with = "Meow meow"  -- The name of the character you're trading with
local destination_server = "Zodiark" -- Set this to the server you're meeting the delivery character on
local destination_type = 0 -- Options: 0 = Aetheryte name, 1 = Estate and meet outside, 2 = Estate and meet inside
local destination_aetheryte = "Aleport" -- Aetheryte to meet at if ["Destination Type"] is set to 0
local destination_house = 0 -- Options: 0 = FC, 1 = Personal, 2 = Apartment // Only active if ["Destination Type"] is set to 1 or 2
local do_movement = false -- Options: true, false // will move to the character you're trading to, usually this is done by the delivery character
local return_home = false -- Options: true, false // will just log out if set to false, otherwise will move to home server and to set location configured by ["Return Location"]
local return_location = 0 -- Options: 0 = do nothing, 1 = limsa, 2 = limsa bell, 3 = nearby bell, 4 = fc 
local items = {
-- This is where you configure what items each character is going to be delivering, the format is {"ITEMNAME", AMOUNT}
-- if you want to do it character specific you have to edit the generated character list afterwards
-- It is not case sensitive, however it needs to be the full name so it doesn't accidentally get the wrong item
-- add or remove as you wish, can even leave it empty just fine
{"Salvaged Ring", 99999},
{"Salvaged Bracelet", 99999},
{"Salvaged Earring", 99999},
{"Salvaged Necklace", 99999},
{"Extravagant Salvaged Ring", 99999},
{"Extravagant Salvaged Bracelet", 99999},
{"Extravagant Salvaged Earring", 99999},
{"Extravagant Salvaged Necklace", 99999}
}

-- This option if set to true will override destination_server and set it to that chars home server
-- If the list is in order it can be used to make everything faster as the characters do not have to travel anywhere, 
-- they just meet the trader on their server at the set location
local set_destination_server_to_home_server = false


--[[#################################
#  DON'T TOUCH ANYTHING BELOW HERE  #
# UNLESS YOU KNOW WHAT YOU'RE DOING #
#####################################

###################
# FUNCTION LOADER #
#################]]


snd_config_folder = os.getenv("appdata") .. "\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\"
vac_config_folder = snd_config_folder .. "\\VAC\\"
load_functions_file_location = os.getenv("appdata") .. "\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\vac_functions.lua"
LoadFunctions = loadfile(load_functions_file_location)
LoadFunctions()
LoadFileCheck()

--[[###########
# MAIN SCRIPT #
#############]]

local function extract_world_from_name(char_name)
    local at_position = string.find(char_name, "@")
    if at_position then
        return string.sub(char_name, at_position + 1)
    end
    return nil
end

local function strip_after_at(input_string)
    local result = string.match(input_string, "([^@]+)")
    return result
end

local function generate_character_list_options()
    local character_list_options = {}

    for _, char in ipairs(gen_char_list) do
        local char_name = char
        local server_to_use = destination_server
        local trading_with_override = trading_with_list[_]
        local trading_with_t = ""
        if trading_with_override ~= nil then
            trading_with_t = strip_after_at(trading_with_override)
        else
            trading_with_t = strip_after_at(trading_with)
        end
        -- If set_destination_server_to_home_server is true, extract the world from the character name
        if set_destination_server_to_home_server then
            server_to_use = extract_world_from_name(char_name) or destination_server
        end
        
        -- Insert the character data into the list and maintain order
        table.insert(character_list_options, {
            ["Name"] = char_name,
            ["Trading With"] = trading_with_t,
            ["Destination Server"] = server_to_use,
            ["Destination Type"] = destination_type,
            ["Destination Aetheryte"] = destination_aetheryte,
            ["Destination House"] = destination_house,
            ["Do Movement"] = do_movement,
            ["Return Home"] = return_home,
            ["Return Location"] = return_location,
            ["Items"] = items,
            -- Order list
            ["_order"] = {
                "Name",
                "Trading With",
                "Destination Server",
                "Destination Type",
                "Destination Aetheryte",
                "Destination House",
                "Do Movement",
                "Return Home",
                "Return Location",
                "Items"
            }
        })
    end

    return character_list_options
end

local character_list_options = generate_character_list_options()

local function write_to_file(filename, data)
    local tools_folder = vac_config_folder .. "Tools\\"
    EnsureFolderExists(vac_config_folder)
    EnsureFolderExists(tools_folder)
    local file = io.open(tools_folder .. filename, "w")

    file:write("local character_list_postmoogle = {\n")
    
    for _, char in ipairs(data) do
        file:write("    {\n")
        local order = char["_order"]
        for _, key in ipairs(order) do
            local value = char[key]
            if type(value) == "string" then
                file:write(string.format("        [\"%s\"] = \"%s\",\n", key, value))
            elseif type(value) == "table" then
                file:write(string.format("        [\"%s\"] = {\n", key))
                for _, item in ipairs(value) do
                    file:write(string.format("            {\"%s\", %d},\n", item[1], item[2]))
                end
                file:write("        },\n")
            else
                file:write(string.format("        [\"%s\"] = %s,\n", key, tostring(value)))
            end
        end
        file:write("    },\n")
    end

    file:write("}\n")
    file:close()
end

write_to_file("Post Moogle Chars.lua", character_list_options)