-- Credits go to Dreamie, Henny & Inku
local current_shift = 0
local gMapTop = 0x0200B650
local gMapBottom = 0x02025EB0
local current_gMap = gMapBottom
local last_frame_inputs = {}
local firerod_tile = 0x0
local tile_index = 0x0
local link_layer = memory.read_u8(0x03001198) -- can be 0 for example on file select screen

local vectorx = 201
local vectory = 121

-- ### FIREROD PRETTY FRAME SECTION ###
local frame_rows = { 0xBFEFFFFFFFFBFE, 0xE5BAAAAAAAAD5B, 0xDB7555555576E7, 0xDE7BFFFFFFF7B7, 0xDBEAAAAAAAB75B, 0xB55555555566FE, 0xEFE0000000069B, 0xE79000000006DB, 0xE79000000006DB, 
0xE79000000006DB, 0xE79000000006DB, 0xE79000000006DB, 0xE79000000006DB, 0xE79000000006DB, 0xE79000000006DB, 0xE79000000006DB, 0xE79000000006DB, 0xE79000000006DB, 0xE79000000006DB, 
0xE79000000006DB, 0xe79000000006db, 0xe6900000000bfb, 0xbf99555555555e, 0xe5deaaaaaaabe7, 0xdedfffffffedb7, 0xdb9d5555555de7, 0xe57aaaaaaaae5b, 0xbfeffffffffbfe} -- pretty frame image compressed at 2bpp

local firerod_frame_palette = { [0] = 0x0, [1] = "#ff634a", [2] = "#bd2942", [3] = "#312142"}

local function draw_firerod_tile_frame(x_offset, y_offset)
    for row = 0,27 do
        for two_bits_var = 0,27 do
            gui.drawPixel(1 + two_bits_var + x_offset, 1 + row + y_offset, firerod_frame_palette[(frame_rows[row + 1] >> (2 *  two_bits_var)) & 3])
        end
    end
end
-- ### FIREROD PRETTY FRAME SECTION ###

local function twobytescolor_to_luacolor(color)
    -- 16 bit color in the format 0bxBBBBBGGGGGRRRRR (x is unused, B G R are blue green red bits)
    local new_luacolor = 0x0
    if color == 0 then
        return 0xFF000000 -- returns black
    else
        new_luacolor = forms.createcolor(((color >> 0) & 0x1F) << 3, ((color >> 5) & 0x1F) << 3, ((color >> 10) & 0x1F) << 3, 0xFF)
        return new_luacolor
    end
end

local function flip_coords(coordinate,max,flip_bit)
    -- flips subtiles coordinates according to horizontal and vertical flip bits
    -- example : for 8 pixels in a single row, if you flip the 0-th place pixel, it's going to end up at place 7, so max has to be 7, not 8
    if flip_bit == 0 then
        return coordinate
    elseif flip_bit == 1 then
        return max - coordinate
    else
        console.log("Error in flipping bit value")
        return coordinate
    end
end

local function reading_color_from_palette(subtile, x_offset, y_offset, layer)
    -- subtile is some 16 bit data formatted as [0-9] : subtile number, [10] : horizontal flip, [11] : vertical flip, [12-15] : palette number
    local subtile_number = subtile & 0x3FF
    local palette_number = (subtile & 0xF000) >> 12
    local horizontal_flip = (subtile & 0x400) >> 10
    local vertical_flip = (subtile & 0x800) >> 11
    local subtile_byte = 0x0

    local layer_memory_offset = 0
    if layer == 2 then
        layer_memory_offset = 512
    end

    for row = 0,7 do
        for byte = 0,3 do
            subtile_byte = memory.read_u8(0x6000000 + 32 * (subtile_number + layer_memory_offset) + byte + 4 * row) -- this works for bottom tiles, add 512 to subtile_number for top tiles to work
            gui.drawPixel(flip_coords(2 * byte, 7, horizontal_flip) + x_offset, flip_coords(row, 7, vertical_flip) + y_offset, twobytescolor_to_luacolor(memory.read_u16_le(0x05000000 + 16 * 2 * palette_number + 2 * (subtile_byte & 0xF))))
            gui.drawPixel(flip_coords(2 * byte + 1, 7, horizontal_flip) + x_offset, flip_coords(row, 7, vertical_flip) + y_offset, twobytescolor_to_luacolor(memory.read_u16_le(0x05000000 + 16 * 2 * palette_number + 2 * ((subtile_byte & 0xF0) >> 4))))
        end
    end
end

local function read_collision()
    -- notable collision values
    -- JP collision : 0x080b3c20
    -- EU collision : 0x080b35a8
    local number = memory.read_u8(0x080b3c20 + firerod_tile)
    local res = ""
    local front_color = "#52dede"
    local text_offset = -12
    if number == 0 then
        res = "Walkable"
        front_color = "#6be64a"
    elseif number == 0x2b then
        res = "Rock Wall"
        front_color = "#7363ce"
        text_offset = -18
    elseif number == 0x17 then
        res = "Ladder"
        front_color = "#7363ce"
    else
        res = string.format("%x",number)
        text_offset = 0
    end
    gui.drawText(vectorx - 2 + text_offset, vectory - 25, res, front_color, "#312142", 10) 
end

while true do
    -- emu loop, current_shift is what helps me go through tiles, starts at 0, increments by 2 since tiles are u16)
    local this_frame_inputs = joypad.get()
    link_layer = memory.read_u8(0x03001198)

    -- updates tileset based on link's current layer
    if link_layer == 2 then
        current_gMap = gMapTop
    else
        current_gMap = gMapBottom
    end

    -- this draws the pretty frame to put the tile into <3
    draw_firerod_tile_frame(vectorx - 6, vectory - 6)

	if this_frame_inputs["A"] then
		local firerod_entity = memory.read_u32_le(0x03003d84)
		firerod_tile = memory.read_u16_le(firerod_entity + 0x6c)
        tile_index = memory.read_u16_le(current_gMap + 0x6004 + 2 * firerod_tile)
    elseif not last_frame_inputs["A"] then
        firerod_tile = 0x0
        tile_index = 0x0
    end

    --[[ ### INFO FROM THE GOOGLE DOC ON COLLISION VALUES ###
    Flagged: $01 Bottom Right, $02 Bottom Left, $04 Top Right, $08 Top Left
    $40 for only Big Blocked (Minish Allowed), $50 for only Big Allowed (Minish Blocked), Both use above.
    $10 Bottom Right Diagonal, $11 Bottom Left Diagonal, $12 Top Right Diagonal, $13 Top Left Diagonal
    $17 Climb Ladder, $1D Destroyable
    $20 Hole, $23 Horizontal Entrance, $27 Vertical Entrance, $28 Rail, $29 Steps, $2B Rock Wall
    ### ### ###
    0x080b35a8 is the ROM linker between firerod tile indices and collision values for EU
    --]]

    -- displays collision value of the tile selected with the firerod
    gui.drawText(vectorx - 25, vectory - 34, "Collision:", "#52dede", "#312142", 10)
    read_collision()

    -- displays the index of the tile selected with the firerod
    gui.drawText(vectorx -2, vectory - 16, string.format("%x",firerod_tile), "#bd2942", "#312142", 10) 

    -- displays the 4 individual subtiles
    reading_color_from_palette(memory.read_u16_le(current_gMap + 0x7004 + 8 * tile_index), vectorx + 1, vectory + 1, link_layer)
    reading_color_from_palette(memory.read_u16_le(current_gMap + 0x7004 + 8 * tile_index + 2), vectorx + 9, vectory + 1, link_layer)
    reading_color_from_palette(memory.read_u16_le(current_gMap + 0x7004 + 8 * tile_index + 4), vectorx + 1, vectory + 9, link_layer)
    reading_color_from_palette(memory.read_u16_le(current_gMap + 0x7004 + 8 * tile_index + 6), vectorx + 9, vectory + 9, link_layer)

    last_frame_inputs = this_frame_inputs
    emu.frameadvance()
end