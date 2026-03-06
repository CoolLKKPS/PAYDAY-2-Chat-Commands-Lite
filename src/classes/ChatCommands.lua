ChatCommands = {}

ChatCommands.name = "COMMAND"
ChatCommands.delimiter = "/"
ChatCommands.colors = {
    info = Color("2980b9"),
    success = Color("27ae60"),
    warning = Color("d35400"),
    danger = Color("c0392b"),
    muted = Color("bdc3c7"),
    white = Color("ffffff")
}

ChatCommands.commands = {
    restart = {
        conditions = {
            isInHeist = true,
            isHost = true
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 0 then
                ChatCommands.usage("restart")
                return
            end
            managers.game_play_central:restart_the_game()
        end,
        help = ChatCommands.delimiter .. "restart"
    },
    disconnect = {
        conditions = {
            isHost = true
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 1 then
                ChatCommands.usage("disconnect")
                return
            end
            local peer = ChatCommands.getPeer(parameters[1])
            if not peer then
                ChatCommands.playerNotFound(parameters[1])
                return
            end
            if ChatCommands.isPeerSelf(peer) then
                ChatCommands.message("You cannot disconnect yourself", ChatCommands.colors.warning)
                return
            end
            local session = managers.network:session()
            session:send_to_peers("kick_peer", peer:id(), 1)
            session:on_peer_kicked(peer, peer:id(), 1)
        end,
        help = ChatCommands.delimiter .. "disconnect <number> | <color>"
    },
    kick = {
        conditions = {
            isHost = true
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 1 then
                ChatCommands.usage("kick")
                return
            end
            local peer = ChatCommands.getPeer(parameters[1])
            if not peer then
                ChatCommands.playerNotFound(parameters[1])
                return
            end
            if ChatCommands.isPeerSelf(peer) then
                ChatCommands.message("You cannot kick yourself", ChatCommands.colors.warning)
                return
            end
            local session = managers.network:session()
            session:send_to_peers("kick_peer", peer:id(), 0)
            session:on_peer_kicked(peer, peer:id(), 0)
        end,
        help = ChatCommands.delimiter .. "kick <number> | <color>"
    },
    ban = {
        conditions = {
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 1 then
                ChatCommands.usage("ban")
                return
            end
            local peer = ChatCommands.getPeer(parameters[1])
            if not peer then
                ChatCommands.playerNotFound(parameters[1])
                return
            end
            if ChatCommands.isPeerSelf(peer) then
                ChatCommands.message("You cannot ban yourself", ChatCommands.colors.warning)
                return
            end
            managers.ban_list:ban(peer:user_id(), peer:name())
            ChatCommands.message(peer:name() .. " has been banned", ChatCommands.colors.info)
            if Network:is_server() then
                local session = managers.network:session()
                session:send_to_peers("kick_peer", peer:id(), 6)
                session:on_peer_kicked(peer, peer:id(), 6)
            end
        end,
        help = ChatCommands.delimiter .. "ban <number> | <color>"
    },
    profile = {
        conditions = {
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 1 then
                ChatCommands.usage("profile")
                return
            end
            local peer = ChatCommands.getPeer(parameters[1])
            if not peer then
                ChatCommands.playerNotFound(parameters[1])
                return
            end
            if Steam then
                local url = "https://steamcommunity.com/profiles/" .. peer:account_id() .. "/stats/PAYDAY2"
                Steam:overlay_activate("url", url)
            else
                ChatCommands.message("Unavailable", ChatCommands.colors.warning)
            end
        end,
        help = ChatCommands.delimiter .. "profile <number> | <color>"
    },
    playtime = {
        conditions = {
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 1 then
                ChatCommands.usage("playtime")
                return
            end
            local peer = ChatCommands.getPeer(parameters[1])
            if not peer then
                ChatCommands.playerNotFound(parameters[1])
                return
            end
            if Steam then
                local url = "http://steamcommunity.com/profiles/" .. peer:account_id() .. "/?l=english"
                dohttpreq(url, ChatCommands.playtimeCallback)
            else
                ChatCommands.message("Unavailable", ChatCommands.colors.warning)
            end
        end,
        help = ChatCommands.delimiter .. "playtime <number> | <color>"
    },
    mods = {
        conditions = {
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 1 then
                ChatCommands.usage("mods")
                return
            end
            local peer = ChatCommands.getPeer(parameters[1])
            if not peer then
                ChatCommands.playerNotFound(parameters[1])
                return
            end
            if ChatCommands.isPeerSelf(peer) then
                ChatCommands.message("You cannot get your own mod list", ChatCommands.colors.warning)
                return
            end
            local mods = peer:synced_mods()
            local count = 0
            local message = "\n"
            for key, mod in ipairs(mods) do
                if not mod.name then
                    goto continue
                end
                if mod.name == "SuperBLT" then
                    goto continue
                end
                count = count + 1
                message = message .. "- " .. mod.name .. "\n"
                ::continue::
            end
            if count > 0 then
                message = message .. tostring(count) .. " mod" .. (count > 1 and "s" or "") .. " installed"
            else
                message = "No mod installed"
            end
            ChatCommands.message(message, ChatCommands.colors.info)
        end,
        help = ChatCommands.delimiter .. "mods <number> | <color>"
    },
    quit = {
        conditions = {
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count ~= 0 then
                ChatCommands.usage("quit")
                return
            end
            os.exit()
        end,
        help = ChatCommands.delimiter .. "quit"
    },
    help = {
        conditions = {
        },
        callback = function(parameters)
            local count = ChatCommands.count(parameters)
            if count == 0 then
                local message = "\n"
                message = message .. ChatCommands.commands["restart"].help .. "\n"
                message = message .. ChatCommands.commands["disconnect"].help .. "\n"
                message = message .. ChatCommands.commands["kick"].help .. "\n"
                message = message .. ChatCommands.commands["ban"].help .. "\n"
                message = message .. ChatCommands.commands["profile"].help .. "\n"
                message = message .. ChatCommands.commands["playtime"].help .. "\n"
                message = message .. ChatCommands.commands["mods"].help .. "\n"
                message = message .. ChatCommands.commands["quit"].help .. "\n"
                message = message .. ChatCommands.commands["help"].help
                ChatCommands.message(message, ChatCommands.colors.info)
            elseif count == 1 then
                if ChatCommands.commands[parameters[1]] then
                    ChatCommands.message(ChatCommands.commands[parameters[1]].help, ChatCommands.colors.info)
                else
                    ChatCommands.message("Invalid command", ChatCommands.colors.danger)
                end
            else
                ChatCommands.usage("help")
            end
        end,
        help = ChatCommands.delimiter .. "help [command_name]"
    }
}

ChatCommands.aliases = {
    p = "profile",
    t = "playtime",
    m = "mods",
    h = "help",
    dc = "disconnect",
    re = "restart"
}

function ChatCommands.execute(message)
    ChatCommands.previousCommand = message
    local parameters = ChatCommands.split(message)
    local name = string.sub(table.remove(parameters, 1), 2)
    if ChatCommands.aliases[name] then
        name = ChatCommands.aliases[name]
    end
    local command = ChatCommands.commands[name]
    
    if not command then
        ChatCommands.message("Invalid command", ChatCommands.colors.danger)
        return
    end
    
    if command.conditions.isInGame then
        if not Utils:IsInGameState() then
            ChatCommands.message("In game only command", ChatCommands.colors.warning)
            return
        end
    end
    
    if command.conditions.isInHeist then
        if not Utils:IsInHeist() then
            ChatCommands.message("In heist only command", ChatCommands.colors.warning)
            return
        end
    end
    
    if command.conditions.IsNotInCustody then
        if Utils:IsInCustody() then
            ChatCommands.message("Not in custody only command", ChatCommands.colors.warning)
            return
        end
    end
    
    if command.conditions.isHost then
        if not Network:is_server() then
            ChatCommands.message("Host only command", ChatCommands.colors.warning)
            return
        end
    end
    
    command.callback(parameters)
end

function ChatCommands.split(string)
    local result = {}
    for element in string:gmatch("%S+") do
        table.insert(result, element)
    end
    return result
end

function ChatCommands.count(table)
    local count = 0
    for key, value in pairs(table) do
        count = count + 1
    end
    return count
end

function ChatCommands.message(message, color)
    managers.chat:_receive_message(1, ChatCommands.name, tostring(message), color or ChatCommands.colors.white)
end

function ChatCommands.usage(name)
    ChatCommands.message("Usage: " .. ChatCommands.commands[name].help, ChatCommands.colors.danger)
end

function ChatCommands.getPeer(value)
    local name = value
    local colors = {
        g = 1,
        green = 1,
        b = 2,
        blue = 2,
        r = 3,
        red = 3,
        y = 4,
        yellow = 4,
        o = 4,
        orange = 4
    }
    local number = nil
    if colors[value] then
        number = colors[value]
    else
        number = tonumber(value)
    end
    if number == nil then
        return false
    end
    local session = managers.network:session()
    return session:peer(number)
end

function ChatCommands.playerNotFound(value)
    ChatCommands.message("Player " .. tostring(value) .. " not found", ChatCommands.colors.warning)
end

function ChatCommands.isPeerSelf(peer)
    return peer:id() == managers.network:session():local_peer():id()
end

function ChatCommands.playtimeCallback(data)
    if type(data) ~= "string" then
        ChatCommands.message("Request failed", ChatCommands.colors.danger)
        return
    end
    local hours_played = "Playtime unavailable"
    local div_tag = "<div class=\"game_info_details\">"
    local start_pos = data:find(div_tag)
    if start_pos then
        local end_pos = data:match(div_tag .. '%s*([%d,.]+)%s*hrs on record')
        if end_pos then
            hours_played = end_pos .. " hours"
        end
    elseif data:find("profile_private_info") then
        hours_played = "Private Profile"
    elseif data:find("store.steampowered.com") then
        hours_played = "Game Info Hidden"
    end
    if hours_played == "Playtime unavailable" then
        ChatCommands.message(hours_played, ChatCommands.colors.warning)
    else
        ChatCommands.message(hours_played, ChatCommands.colors.info)
    end
end
