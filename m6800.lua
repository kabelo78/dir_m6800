-- Basic AudioControl Director M6800 Lua Driver for BeoLiving Intelligence

-- Driver metadata
driver_label = "AudioControl M6800 - Basic"
driver_min_blgw_version = "1.5.0"
driver_version = "0.9"
driver_help = [[
Basic driver for controlling the AudioControl Director M6800 amplifier.
Supports:
- Turning on/off individual zones (1-8)
- Selecting analog and digital sources for each zone
- Adjusting volume for each zone using a virtual slider available under Scenes
]]

-- Define the TCP communication channel
driver_channels = {
   TCP(23, "192.168.1.100", "Ethernet", "Telnet connection to M6800") -- Replace with actual IP address
}

-- Define available resources (zones and commands)
resource_types = {
    ["Zone"] = {
        standardResourceType = "_AUDIO_ZONE",
        address = stringArgument("address", "1"),
        commands = {
            _POWER_ON = {},
            _POWER_OFF = {},
            _SET_SOURCE_ANALOG = { arguments = { _input = { type = "string", default = "1" } } },
            _SET_SOURCE_DIGITAL = { arguments = { _input = { type = "string", default = "a" } } },
            _SET_VOLUME = { arguments = { _level = { type = "float", min = 0, max = 100 } } }
        },
        events = {
            _POWER_ON = {},
            _POWER_OFF = {},
            _SOURCE_CHANGED = { arguments = { _input = { type = "string", default = "1" } } },
            _VOLUME_CHANGED = { arguments = { _level = { type = "float", min = 0, max = 100 } } }
        }
    },
    ["VolumeControl"] = {
        standardResourceType = "DIMMER",
        address = stringArgument("address", "1"),

        commands = {
            SET= {
                context_help= "Set the dimmer level.",
                arguments= { numericArgument("LEVEL", 0, 0, 100, { context_help = "Adjusts the volume level" } ) } }
        },
        events = {
            _LEVEL_CHANGED = { arguments = { LEVEL = numericArgument("LEVEL", 0, 0, 100) } }
        }
    }
}

-- Function to send a command to the amplifier
local function sendCommand(command)
    local err = channel.write(command .. "\r\n")
    if err ~= CONST.OK then
        Error("Failed to send command: " .. command)
    end
end

-- Command executions
function executeCommand(command, resource, args)
    local zone = resource.address
    
    if command == "_POWER_ON" then
        sendCommand("Z" .. zone .. "on")
    elseif command == "_POWER_OFF" then
        sendCommand("Z" .. zone .. "off")
    elseif command == "_SET_SOURCE_ANALOG" then
        sendCommand("Z" .. zone .. "sourceMX" .. args._input)
    elseif command == "_SET_SOURCE_DIGITAL" then
        sendCommand("Z" .. zone .. "sourceDX" .. args._input)
    elseif command == "SET" then
        local volume = math.floor(args.LEVEL) -- Ensure volume is an integer
        sendCommand("Z" .. zone .. "vol" .. volume)
    end
end

-- Process function to maintain the connection
function process()
    Trace("M6800 basic driver process started")
    if channel.status() then
        driver.setOnline()
    end
    while channel.status() do
        local err, response = channel.readUntil("\r\n")
        if err == CONST.OK then
            Trace("Received: " .. response)
        end
    end
    channel.retry("Connection lost, retrying in 10s", 10)
    driver.setError()
    return CONST.HW_ERROR
end
