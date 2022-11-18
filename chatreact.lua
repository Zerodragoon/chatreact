_addon.name     = 'chatreact'
_addon.author   = 'Zerodragoon'
_addon.version  = '1.0'
_addon.commands = {'cr', 'chatreact'}

res = require('resources')
config = require('config')

local commands = {}
local monitor_messages = true

local settings = T{
    chat_messages = L{}
}

do
    local file_path = windower.addon_path..'data/settings.lua'
    local table_tostring

    table_tostring = function(tab, padding) 
        local str = ''
        for k, v in pairs(tab) do
            if class(v) == 'List' then
                str = str .. '':rpad(' ', padding) .. '["%s"] = L{':format(k) .. table_tostring(v, padding+4) .. '},\n'
            elseif class(v) == 'Table' then
                str = str .. '':rpad(' ', padding) .. '["%s"] = T{\n':format(k) .. table_tostring(v, padding+4) .. '':rpad(' ', padding) .. '},\n'
            elseif class(v) == 'table' then
                str = str .. '':rpad(' ', padding) .. '["%s"] = {\n':format(k) .. table_tostring(v, padding+4) .. '':rpad(' ', padding) .. '},\n'
            elseif class(v) == 'string' then
                str = str .. '"%s",':format(v)
            end
        end
        return str
    end

    save_file = function()
        local make_file = io.open(file_path, 'w')
        
        local str = table_tostring(settings, 4)

        make_file:write('return {\n' .. str .. '}\n')
        make_file:close()
    end

    if windower.file_exists(file_path) then
        settings = settings:update(dofile(file_path))
    else
        save_file()
    end
end

local function has_value_list (tab, message)
    for index, value in ipairs(tab) do
        if message:find(value) then
            return true
        end
    end

    return false
end

local function get_value_list (tab, message)
    for index, value in ipairs(tab) do
        if message:find(value) then
            return value
        end
    end
end

local function get_value_index (tab, message)
    for index, value in ipairs(tab) do
        if message:find(value) then
            return index
        end
    end
end

local function add_message(item) 
	item = item:lower()
	
	if settings.chat_messages:contains(item) then
		return 'Chat message already set to alert'
	else 
		windower.add_to_chat(1,'Message \"'.. item ..'\" Added')                           
		settings.chat_messages:append(item)
		save_file()
	end
end

local function remove_message(item) 
	item = item:lower()

	if has_value_list(settings.chat_messages, item) then
		windower.add_to_chat(1,'Message \"'.. item ..'\" Removed')
		list.remove(settings.chat_messages, get_value_index(settings.chat_messages, item))
		save_file()
	else
		return 'Message to remove not found'
	end
end

local function clear() 
	windower.add_to_chat(1,'All Messages Cleared')                           
	settings.chat_messages:clear()
	save_file()
end

local function print_settings()
	local messages_str = 'Messages Settings: '
	
	for k,v in ipairs(settings.chat_messages) do
		messages_str = messages_str..'\n   %d:[%s]':format(k, v)
    end
	
	windower.add_to_chat(1,''..messages_str..'')	
end

local function help()
	local messages_str = 'Welcome to Chat React, a tool for monitoring yells and tells for specific key words that outputs a call in party chat when a message is found \n \n '
	
	messages_str = messages_str..'Commands: \n'
	messages_str = messages_str..'  Start: Starts monitoring messages (the addon monitors messages by default on load) \n'
	messages_str = messages_str..'  Stop: Stop monitoring messages \n'
	messages_str = messages_str..'  Help: Brings up this help menu \n'
	messages_str = messages_str..'  Settings: Print the current saved settings \n'
	messages_str = messages_str..'  Add_Message: Adds a message to monitor. ie: cr add_message "ashera harness" \n'
	messages_str = messages_str..'  Remove_Message: Removes a message. ie: cr remove_message "ashera harness" \n'
	messages_str = messages_str..'  Clear: Clears all messages saved for monitoring  \n'

	windower.add_to_chat(1,''..messages_str..'')	
end

local function start()
	windower.add_to_chat(1,'Started monitoring messages')                           
	monitor_messages = true
end

local function stop()
	windower.add_to_chat(1,'Stopped monitoring messages')                           
	monitor_messages = false
end

local function handle_command(...)
    local cmd  = (...) and (...):lower()
    local args = {select(2, ...)}
    if commands[cmd] then
        local msg = commands[cmd](unpack(args))
        if msg then
            windower.add_to_chat(1,'Error running command: '..tostring(msg)..'')                           
        end
    else
		windower.add_to_chat(1,'Unknown command: '..cmd..'')                           
    end
end

commands['start'] = start
commands['stop'] = stop
commands['help'] = help
commands['settings'] = print_settings
commands['add_message'] = add_message
commands['remove_message'] = remove_message
commands['clear'] = clear

windower.register_event('addon command', handle_command)
windower.register_event('chat message', function(message,sender,mode,gm)

	if monitor_messages then 
		--Ignore it if it's not party chat or a tell
		if mode ~= 26 then return end

		message = message:lower()
	 
		if has_value_list(settings.chat_messages, message) then
			windower.play_sound(windower.addon_path..'call10.wav')
			windower.add_to_chat(1,'Message detected ' .. get_value_list(settings.chat_messages, message) .. ' sent by ' .. sender)                           
		end
	end
 
end)