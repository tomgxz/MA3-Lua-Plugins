local c = Cmd
local ti = TextInput

function pos_declare_timing_values(half_second)
    local fades = {}
    local delays_from = {}
    local delays_to = {}

    fades[1] = 0
    fades[2] = 0.25
    fades[3] = 0.5
    fades[4] = 1
    fades[5] = '(Color Picker X Fade)'
    
    delays_from[1] = 0
    delays_from[2] = 0.25
    delays_from[3] = 0.5
    delays_from[4] = 1
    delays_from[5] = '(Color Picker X Delay-from)'
    
    delays_to[1] = 0
    delays_to[2] = 0.25
    delays_to[3] = 0.5
    delays_to[4] = 1
    delays_to[5] = '(Color Picker X Delay-to)'

        
    local groups = {}
        groups[1] = 0
        groups[2] = 2
        groups[3] = 3
        groups[4] = 4
        groups[5] = '(Color Picker X Groups)'

    local wings = {}
        wings[1] = 0
        wings[2] = 2
        wings[3] = 4
        wings[4] = 6
        wings[5] = '(Color Picker X Wings)'

    return fades,delays_from,delays_to,groups,wings
end