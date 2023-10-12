-- relative layout position (top left)
local gl_start_pos_x = -500
local gl_start_pos_y = 200

-- gap between layout elements, doesn't account for el width
local gl_gap_x = 55
local gl_gap_y = 55

-- element size
local gl_size_x = 50
local gl_size_y = 50

local gl_progress_bar_time = 0 -- time for every progress bar status update

local default_layout_number = 2

local c = Cmd -- used for executing commands
local ti = TextInput
local data_pool
local gl_first_appear
local gl_first_sequence
local gl_matricks_first
local gl_first_macro
local gl_first_symbol
local gl_name_prefix

local function color_picker_generator_main()
    data_pool = tonumber(DataPool().no)

    -- init color preset variables
    local pos_presets = {}
    local presets_colors_R = {}
    local presets_colors_G = {}
    local presets_colors_B = {}

    -- get pools from ma3
    local macro_pool = ShowData().datapools[data_pool].Macros
    local pos_presets_pool = ShowData().datapools[data_pool].PresetPools[2]
    local appearances_pool = ShowData().Appearances
    local matricks_pool = ShowData().DataPools[data_pool].MAtricks
    local groups_pool = ShowData().DataPools[data_pool].Groups
    local layouts_pool = ShowData().datapools[data_pool].Layouts
    local sequence_pool = ShowData().datapools[data_pool].Sequences
    local symbols_pool = ShowData().MediaPools.Symbols

    -- init local variables
    local number_of_pos_presets
    local groups_selected
    local number_of_groups
    local layout_number
    local generated
    local symbols_file_names
    local suggested
    local amount

    ----------------------------------------------------------

    generated = 0
    groups_selected = pos_get_groups(data_pool) -- get groups from user

    -- if length of groups selected != 0...
    if #groups_selected ~= 0 then

        c('clearall /nu')
        
        -- get the existing presets from get_presets.lua fn
        local get_pos_presets_return = pos_get_pos_presets(data_pool)

        pos_presets = get_pos_presets_return -- table of pos presets
        number_of_pos_presets = #pos_presets -- number of pos presets

        number_of_groups = #groups_selected -- number of groups
        local presets_selection_exist = true -- flag for whether there are any defined presets

        -- if there were presets selected...
        if number_of_pos_presets ~= 0 then

            -- get first sequence number
            amount = number_of_pos_presets * number_of_groups -- get total number of tiles to calculate required sequence space
            suggested = pos_get_first_pool_num(amount, sequence_pool) -- suggested first sequence number based on available space
            gl_first_sequence = pos_check_selected_pool_num('first Sequence', suggested, amount, sequence_pool) -- get validated user input

            -- get layout number
            suggested = pos_get_first_pool_num(1, layouts_pool) -- suggested first layout number based on first free slot
            layout_number = pos_check_selected_pool_num('Layout number', suggested, 1, layouts_pool) -- get validated user input

            -- get first appearance number
            amount = number_of_pos_presets * 3 + 25 * 2 + 1 + 2 -- 1 is for one additional appearance for macro, 2 is for 2 favourites appearances, 25 for the amount of timing macros
            suggested = pos_get_first_pool_num(amount, appearances_pool) -- suggested first appearance number based on available space
            gl_first_appear = pos_check_selected_pool_num('first Appearance', suggested, amount, appearances_pool) -- get validated user input

            -- get first matricks
            amount = number_of_groups
            suggested = pos_get_first_pool_num(amount, matricks_pool) -- suggested first matricks based on available space
            gl_matricks_first = pos_check_selected_pool_num('first MAtricks', suggested, amount, matricks_pool) -- get validated user input

            -- get first macro
            amount = number_of_pos_presets + 25 + 2 + 17 -- 2 is for two additional macros, 25 for the amount of timing macros, 17 for favourite macros
            suggested = pos_get_first_pool_num(amount, macro_pool) -- suggested first macro based on available space
            gl_first_macro = pos_check_selected_pool_num('first Macro', suggested, amount, macro_pool) -- get validated user input
            

            -- START GENERATION OF LAYOUT

            c('clearall /nu') -- clear command line

            -- turn off program time master, if it is active
            local progtime = MasterPool()['Grand']['ProgramTime'].faderenabled 
            if progtime then c('off master 2.8') end

            -- get name prefix for generated content
            gl_name_prefix = pos_create_name_prefix(data_pool)
            
            -- create new layout, label it, and select it
            c('store layout ' .. layout_number .. ' /nu')
            c('label layout ' .. layout_number .. ' "Pos Selector ' .. gl_name_prefix:gsub('%D*', '') .. '" /nu')
            c('select layout ' .. layout_number .. ' /nu')

            -- get declared timings
            local declared_timings = {pos_declare_timing_values()}

            -- create progress bar
            local progHandle = StartProgress("Generating Position Selector")
            SetProgressRange(progHandle, 1, 16) -- set min and max of range

            local last_appearance_num = pos_create_appearances(pos_presets, gl_first_appear, declared_timings, gl_name_prefix, gl_progress_bar_time, data_pool)

            SetProgress(progHandle, 2)
            coroutine.yield(gl_progress_bar_time)

            -- create matricks
            create_pos_matricks(gl_matricks_first, groups_selected, gl_name_prefix, data_pool)

            local create_timing_macros_return = {pos_create_timing_macros(gl_first_macro, declared_timings, gl_name_prefix, gl_progress_bar_time, data_pool)}
            local last_macro_num = create_timing_macros_return[1]
            local timing_macros_amount = create_timing_macros_return[2]

            SetProgress(progHandle, 3)
            coroutine.yield(gl_progress_bar_time)

            -- create sequences with color values in
            create_pos_sequences(gl_first_sequence, groups_selected, gl_matricks_first, pos_presets,
                gl_first_appear, gl_name_prefix, gl_progress_bar_time, data_pool)

            SetProgress(progHandle, 4)
            coroutine.yield(gl_progress_bar_time)

            -- something
            local last_layout_obj_num = pos_sequences_layout_align(number_of_pos_presets, number_of_groups, gl_size_x,
                gl_size_y, gl_gap_x, gl_gap_y, gl_start_pos_x, gl_start_pos_y, gl_first_sequence, layout_number,
                gl_progress_bar_time, data_pool)

            SetProgress(progHandle, 5)
            coroutine.yield(gl_progress_bar_time)

            -- align groups
            last_layout_obj_num = pos_layout_align_groups(last_layout_obj_num, gl_size_x, gl_size_y, gl_gap_x, gl_gap_y,
                gl_start_pos_x, gl_start_pos_y, groups_selected, layout_number, gl_progress_bar_time, data_pool)

            SetProgress(progHandle, 6)
            coroutine.yield(gl_progress_bar_time)

            -- create group macros
            last_macro_num = pos_create_all_groups_macros(last_macro_num, pos_presets, gl_first_appear, gl_name_prefix,
                gl_progress_bar_time, data_pool)

            SetProgress(progHandle, 7)
            coroutine.yield(gl_progress_bar_time)

            -- align group macros
            last_layout_obj_num = pos_layout_align_all_groups_macros(last_layout_obj_num, last_macro_num, gl_size_x,
                gl_size_y, gl_gap_x, gl_gap_y, gl_start_pos_x, gl_start_pos_y, number_of_pos_presets, layout_number,
                gl_progress_bar_time, data_pool)

            SetProgress(progHandle, 8)
            coroutine.yield(gl_progress_bar_time)

            -- align timing macros
            last_layout_obj_num = pos_layout_align_timing_macros(last_layout_obj_num, timing_macros_amount,
                gl_first_macro, gl_size_x, gl_size_y, gl_gap_x, gl_gap_y, gl_start_pos_x, gl_start_pos_y,
                number_of_groups, layout_number, gl_name_prefix, gl_progress_bar_time, data_pool)

            SetProgress(progHandle, 9)
            coroutine.yield(gl_progress_bar_time)

            -- create off macro
            last_macro_num = pos_create_off_macro(last_macro_num, last_appearance_num, gl_name_prefix, data_pool)

            SetProgress(progHandle, 10)
            coroutine.yield(gl_progress_bar_time)

            -- align off macro
            last_layout_obj_num = pos_layout_align_off_macro(last_layout_obj_num, gl_size_x, gl_size_y, gl_gap_x,
                gl_gap_y, gl_start_pos_x, gl_start_pos_y, last_macro_num, number_of_groups, layout_number, data_pool)

            SetProgress(progHandle, 11)
            coroutine.yield(gl_progress_bar_time)
            
            -- label objects
            last_layout_obj_num = pos_labelling_objects_layout(last_layout_obj_num, gl_size_x, gl_size_y, gl_gap_x,
                gl_gap_y, gl_start_pos_x, gl_start_pos_y, layout_number, number_of_groups, pos_presets,
                declared_timings, gl_name_prefix, gl_progress_bar_time, data_pool)

            SetProgress(progHandle, 12)
            coroutine.yield(gl_progress_bar_time)

            StopProgress(progHandle)

            -- if program time master was disabled, enable it
            if progtime then c('on master 2.8') end

        else Confirm('No presets selected')
        end

    else Confirm('No groups selected')
    end

end

return color_picker_generator_main
