local c = Cmd
local ti = TextInput

local function get_presets_input_with_ranges(input,suggested,object_pool)
    local user_input = input
    local result
    local first, last
    local range = {}
    if user_input ~= suggested and user_input ~= nil then
        result = user_input:gsub('[Tthru]*',{['thru'] = '-', ['t'] = '-', ['Thru'] = '-'})
        if result:match('%d+%s+-%s+%d+') then
            first, last = result:match('(%d+)%s+-%s+(%d+)')
            first = tonumber(first)
            last = tonumber(last)
        elseif tonumber(user_input) ~= nil then
            first = tonumber(user_input:match('%D*(%d+).*'))
            last = tonumber(user_input:match('%D*(%d+).*'))
        else
            first = 'incorrect'
            last = 'incorrect'
        end
        -- local sum = last - first
        if first == 'incorrect' then
            Confirm('Incorrect input')
        elseif last >= first then
            if first ~= nil then
                while first <= last do
                    table.insert(range,first)
                    first = first + 1
                end
            end
        elseif last <= first then 
            if first ~= nil then
                while first >= last do
                    table.insert(range,first)
                    first = first - 1
                end
            end
        end
        if #range == 1 then
            result = range[1]
        else
            result = range
        end
    elseif user_input == nil then
        result = nil
    else
        result = user_input
    end
    if type(result) == 'table' then
        local amount_of_entries = #result
        local deleted
        local ind = 1
        while ind <= amount_of_entries do
            if object_pool[result[ind]] == nil or object_pool[result[ind]].storeddata ~= 'Universal' then
                table.remove(result,ind)
                deleted = true
                ind = ind
                amount_of_entries = #result
            else
                ind = ind + 1
            end
        end
        if deleted then
            Confirm('Non-universal/not existing presets deleted from range')
        end
        -- for k,v in pairs(result) do
        --     Echo(k..' '..v)
        -- end
    end
    -- Echo(result)
    return result
end

function pos_get_pos_presets(DP)
    local DONE = '[DONE]'
    local userInput
    local pos_presets = {}
    local pr_i = 1
    local last_line

    local PosPresetPool = ShowData().DataPools[DP].PresetPools[2] -- get position preset pool
    
    repeat 
        userInput = get_presets_input_with_ranges(ti('Enter position preset ID or range in format: X Thru Y', DONE),DONE,PosPresetPool)
        
        if userInput ~= '' and userInput ~= nil then
        
            if userInput ~= DONE then -- if not finished

                if type(userInput) ~= 'table' and PosPresetPool[userInput] == nil then Confirm('Preset doesn\'t exist')
                
                elseif type(userInput) ~= 'table' then

                    table.insert(pos_presets,userInput)
                        if #pos_presets > 1 then
                            last_line = #pos_presets
                            local ind = 1
                            local deleted
                            repeat
                                if pos_presets[ind] == pos_presets[last_line] then
                                    table.remove(pos_presets,last_line)
                                    deleted = true
                                    Confirm('You\'ve already used this preset')
                                else
                                    ind = ind + 1
                                end
                            until deleted == true or ind == last_line
                        end
                    pr_i = pr_i + 1

                elseif type(userInput) == 'table' then
                    for ind = 1, #userInput do
                        local exists
                        for idx = 1, #pos_presets do
                            if pos_presets[idx] == userInput[ind] then
                                exists = true
                            end
                        end
                        if not exists then
                            table.insert(pos_presets,userInput[ind])
                        end
                    end
                end
            else
            end
        end
    until userInput == DONE or userInput == nil
    
    local amount_of_presets = #pos_presets
    local GPD = GetPresetData
    
    for i = 1, amount_of_presets do
        if GPD(PosPresetPool[pos_presets[i]])[3] == nil then
            c('universal 1 at preset 4.'..pos_presets[i]..' /nu;store preset 4.'..pos_presets[i]..' /m /nu;clearall /nu')
        end
    end
    
    return pos_presets
end