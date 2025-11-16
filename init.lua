-- Load support for translation.
local S = minetest.get_translator("wally")

-- ===================================================================
-- >>>>>               BLOQUES DE MUROS ORIGINALES             <<<<<
-- ===================================================================

-- Tabla con todos los muros que se registrarán.
-- Formato: {"nombre_del_nodo", "Descripción en el inventario", "material_base"}
wally_walls = {
    -- default
    {"wally:brick", "Brick Wall", "default:brick"},
    {"wally:stonebrick", "Stone Brick Wall", "default:stonebrick"},
    {"wally:desert_stonebrick", "Desert Stone Brick Wall", "default:desert_stonebrick"},
    {"wally:sandstonebrick", "Sandstone Brick Wall", "default:sandstonebrick"},
    {"wally:desert_sandstone_brick", "Desert Sandstone Brick Wall", "default:desert_sandstone_brick"},
    {"wally:silver_sandstone_brick", "Silver Sandstone Brick Wall", "default:silver_sandstone_brick"},
    {"wally:obsidianbrick", "Obsidian Brick Wall", "default:obsidianbrick"},
    -- nether (si tienes el mod nether)
    {"wally:netherbrick", "Nether Brick Wall", "nether:brick"},
    {"wally:netherbrick_compressed", "Compressed Nether Brick Wall", "nether:brick_compressed"},
    {"wally:netherbrick_cracked", "Cracked Nether Brick Wall", "nether:brick_cracked"},
    {"wally:netherbrick_deep", "Deep Nether Brick Wall", "nether:brick_deep"},
    -- ethereal (si tienes el mod ethereal)
    {"wally:icebrick", "Ice Brick Wall", "ethereal:icebrick"},
    {"wally:snowbrick", "Snow Brick Wall", "ethereal:snowbrick"},
    -- xdecor (si tienes el mod xdecor)
    {"wally:cactusbrick", "Cactus Brick Wall", "xdecor:cactusbrick"},
    {"wally:moonbrick", "Moon Brick Wall", "xdecor:moonbrick"},
    -- sumpf (si tienes el mod sumpf)
    {"wally:junglestonebrick", "Swamp Stone Brick Wall", "sumpf:junglestonebrick"},
}

-- Bucle para registrar cada muro definido en la tabla 'wally_walls'
for _, wall_data in pairs(wally_walls) do
    local wall_name = wall_data[1]
    local wall_desc = wall_data[2]
    local material_node = wall_data[3]

    if minetest.registered_nodes[material_node] then
        walls.register(wall_name, S(wall_desc), minetest.registered_nodes[material_node].tiles,
                       material_node, minetest.registered_nodes[material_node].sounds)
        local groups = table.copy(minetest.registered_nodes[material_node].groups or {})
        groups.wall = 1
        minetest.override_item(wall_name, {groups = groups})
    end
end


-- ===================================================================
-- >>>>>      MODIFICACIÓN DE XPANES (MÉTODO SIMPLE Y DIRECTO)   <<<<<
-- ===================================================================

if minetest.get_modpath("xpanes") then

    -- Usamos 'minetest.after' para asegurar que los nodos de xpanes existan.
    minetest.after(0, function()

        -- >>>>> MODIFICACIÓN PARA LAS BARRAS DE ACERO <<<<<
        if minetest.registered_nodes["xpanes:bar_flat"] then
            minetest.override_item("xpanes:bar_flat", {
                on_place = function(itemstack, placer, pointed_thing)
                    if pointed_thing.type ~= "node" then return itemstack end
                    local pos = pointed_thing.above
                    
                    -- Paso 1: Dejamos que el juego coloque el panel.
                    local returned_itemstack = minetest.item_place(itemstack, placer, pointed_thing)
                    
                    -- Paso 2: Inmediatamente lo intercambiamos por el poste.
                    minetest.swap_node(pos, {name = "xpanes:bar", param2 = 0})
                    
                    return returned_itemstack
                end
            })
            minetest.log("action", "[wally] 'xpanes:bar_flat' modificado para colocar un poste (método simple).")
        end

        -- >>>>> MODIFICACIÓN PARA LOS PANELES DE CRISTAL <<<<<
        if minetest.registered_nodes["xpanes:pane_flat"] then
            minetest.override_item("xpanes:pane_flat", {
                on_place = function(itemstack, placer, pointed_thing)
                    if pointed_thing.type ~= "node" then return itemstack end
                    local pos = pointed_thing.above

                    local returned_itemstack = minetest.item_place(itemstack, placer, pointed_thing)
                    
                    -- Intercambiamos por el poste de cristal.
                    minetest.swap_node(pos, {name = "xpanes:pane", param2 = 0})
                    
                    return returned_itemstack
                end
            })
            minetest.log("action", "[wally] 'xpanes:pane_flat' modificado para colocar un poste (método simple).")
        end
    end)
end

-- ===================================================================
-- >>>>>       FIN DE LA MODIFICACIÓN DE XPANES (SIMPLE)        <<<<<
-- ===================================================================

-- ===================================================================
-- >>>>>        SOPORTE OPCIONAL PARA EL MOD 'darkage'        <<<<<
-- ===================================================================

if minetest.get_modpath("darkage") then

    local darkage_bricks = {
        "darkage:basalt_brick", "darkage:slate_brick", "darkage:gneiss_brick",
        "darkage:chalked_bricks", "darkage:ors_brick",
    }

    for _, material_node in ipairs(darkage_bricks) do
        if minetest.registered_nodes[material_node] then
            local mod_name, item_name = material_node:match("^(.+):(.+)$")
            local wall_name = "wally:" .. mod_name .. "_" .. item_name .. "_wall"
            local base_name = string.gsub(item_name, "s$", "")
            local pretty_name = string.gsub(base_name, "^%l", string.upper)
            local wall_desc = S(pretty_name .. " Brickwall")

            -- >>>>> REGISTRO SIMPLIFICADO: SIN LÓGICA DE CONEXIONES AQUÍ <<<<<
            minetest.register_node(wall_name, {
                description = wall_desc,
                drawtype = "nodebox",
                paramtype = "light",
                is_ground_content = false,
                sunlight_propagates = true,
                paramtype2 = "facedir",
                tiles = minetest.registered_nodes[material_node].tiles,
                groups = table.copy(minetest.registered_nodes[material_node].groups or {}),
                sounds = minetest.registered_nodes[material_node].sounds,
                connect_sides = {"left", "right", "front", "back"},
                -- No hay 'connects_to' aquí. El bucle final se encargará.
                node_box = {
                    type = "connected",
                    fixed = {{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4}},
                    connect_front = {{-3/16, -1/2, -1/2, 3/16, 3/8, -1/4}},
                    connect_left = {{-1/2, -1/2, -3/16, -1/4, 3/8, 3/16}},
                    connect_back = {{-3/16, -1/2, 1/4, 3/16, 3/8, 1/2}},
                    connect_right = {{1/4, -1/2, -3/16, 1/2, 3/8, 3/16}},
                },
                selection_box = {
                    type = "connected",
                    fixed = {{-1/4, -1/2, -1/4, 1/4, 1/2, 1/4}},
                    connect_front = {{-3/16, -1/2, -1/2, 3/16, 3/8, -1/4}},
                    connect_left = {{-1/2, -1/2, -3/16, -1/4, 3/8, 3/16}},
                    connect_back = {{-3/16, -1/2, 1/4, 3/16, 3/8, 1/2}},
                    connect_right = {{1/4, -1/2, -3/16, 1/2, 3/8, 3/16}},
                },
            })

            -- Añadimos los grupos necesarios.
            local groups = minetest.registered_nodes[wall_name].groups
            groups.wall = 1
            groups.wally_darkage_wall = 1
            minetest.override_item(wall_name, {groups = groups})

            minetest.register_craft({
                output = wall_name .. " 6",
                recipe = {
                    {material_node, material_node, material_node},
                    {material_node, material_node, material_node},
                    {"", "", ""},
                }
            })

            minetest.log("action", "[wally] Muro de 'darkage' (sin conexiones) creado: " .. wall_name)
        else
            minetest.log("warning", "[wally] El nodo 'darkage' no se encontró: " .. material_node)
        end
    end
    minetest.log("action", "[wally] Soporte completo para 'darkage' cargado.")
end

-- ===================================================================
-- >>>>>       FIN DEL SOPORTE OPCIONAL PARA 'darkage'        <<<<<
-- ===================================================================

-- ===================================================================
-- >>>>> BUCLE FINAL DE CONEXIÓN UNIVERSAL (TODO EN UNO)       <<<<<
-- ===================================================================

minetest.register_on_mods_loaded(function()
    -- >>>>> LISTA DE CONEXIONES PARA MUROS (NO SE CONECTAN A VALLAS DE MADERA) <<<<<
    local wall_connects_to = {
        "group:wall", "group:pane", "group:glass",
        "group:stone", "group:sand",
        -- Lámparas de darkage
        "darkage:lamp", "darkage:glow_glass", "darkage:glow_glass_square", 
        "darkage:glow_glass_round", "darkage:glass_square",
        -- Bloques base de darkage
        "darkage:basalt_brick", "darkage:slate_brick", "darkage:gneiss_brick",
        "darkage:chalked_bricks", "darkage:ors_brick"
    }
    
    -- >>>>> LISTA DE CONEXIONES PARA VALLAS DE MADERA (NO SE CONECTAN A MUROS) <<<<<
    local fence_connects_to = {
        "group:fence", "group:pane", "group:glass",
        "group:wood", "group:tree",  -- ¡Añadido! Para que se conecten a madera y troncos
        -- Lámparas de darkage
        "darkage:lamp", "darkage:glow_glass", "darkage:glow_glass_square", 
        "darkage:glow_glass_round", "darkage:glass_square",
        -- Nodos de madera específicos del juego base
        "default:wood", "default:junglewood", "default:pine_wood", 
        "default:acacia_wood", "default:aspen_wood",
        "default:tree", "default:jungletree", "default:pine_tree", 
        "default:acacia_tree", "default:aspen_tree"
    }

    -- Aplicar conexiones a los muros
    for n, def in pairs(minetest.registered_nodes) do
        if def.groups.wall == 1 and not def._is_dynamic_wall then
            minetest.override_item(n, {
                connects_to = wall_connects_to
            })
        end
    end
    
    -- Aplicar conexiones a las vallas de madera
    for n, def in pairs(minetest.registered_nodes) do
        if def.groups.fence == 1 then
            minetest.override_item(n, {
                connects_to = fence_connects_to
            })
        end
    end
    
    -- Aplicar conexiones a los paneles y postes
    for n, def in pairs(minetest.registered_nodes) do
        if def.groups.pane == 1 or def.groups.wally_custom_post == 1 then
            minetest.override_item(n, {
                connects_to = wall_connects_to  -- Los paneles se conectan como los muros
            })
        end
    end
    
    minetest.log("action", "[wally] Conexiones separadas aplicadas: muros no se conectan a vallas de madera, pero las vallas sí se conectan a madera y troncos.")
end)

-- ===================================================================
-- >>>>>  FIN DEL BUCLE FINAL DE CONEXIÓN UNIVERSAL (TODO EN UNO)  <<<<<
-- ===================================================================
