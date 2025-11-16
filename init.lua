-- Cargar soporte para traducción.
local S = minetest.get_translator("wally")

-- ===================================================================
-- >>>>>       LISTA BLANCA DE BLOQUES PARA CREAR MUROS        <<<<<
-- ===================================================================
-- Esta es la lista principal que controla qué bloques se pueden
-- convertir en muros. Para añadir soporte para un nuevo bloque,
-- simplemente añade su nombre de nodo a esta lista.
-- Ejemplo: "nombre_del_mod:nombre_del_bloque"

local wally_whitelisted_blocks = {
    -- Default (Juego Base)
    "default:brick",
    "default:stonebrick",
    "default:desert_stonebrick",
    "default:sandstonebrick",
    "default:desert_sandstone_brick",
    "default:silver_sandstone_brick",
    "default:obsidianbrick",
    
    -- Nether
    "nether:brick",
    "nether:brick_compressed",
    "nether:brick_cracked",
    "nether:brick_deep",
    
    -- Ethereal
    "ethereal:icebrick",
    "ethereal:snowbrick",
    
    -- XDecor
    "xdecor:cactusbrick",
    "xdecor:moonbrick",
    
    -- Sumpf
    "sumpf:junglestonebrick",
    
    -- Darkage
    "darkage:basalt_brick",
    "darkage:slate_brick",
    "darkage:gneiss_brick",
    "darkage:chalked_bricks",
    "darkage:ors_brick",
    "darkage:gneiss",
    "darkage:schist" -- <<< ¡AÑADIDO COMO PEDISTE!
}

-- ===================================================================
-- >>>>>    REGISTRO AUTOMÁTICO DE MUROS (MÉTODO UNIFICADO)    <<<<<
-- ===================================================================

-- Esta tabla guardará los bloques base para la lógica de conexión al final.
local base_blocks_for_connection = {}

-- Bucle unificado que procesa TODOS los bloques de la lista blanca.
for _, material_node in ipairs(wally_whitelisted_blocks) do

    -- Nos aseguramos de que el bloque base exista en el juego.
    if minetest.registered_nodes[material_node] then
        -- 1. Extraer nombres para usarlos en el nuevo muro.
        local mod_name, item_name = material_node:match("^([^:]+):(.+)$")
        local wall_name = "wally:" .. item_name .. "_wall"
        
        -- 2. Crear una descripción legible (Ej: "desert_stone_brick" -> "Desert Stone Brick Wall").
        local pretty_name = string.gsub(item_name, "_", " ")
        pretty_name = string.gsub(pretty_name, "^%l", string.upper) -- Pone la primera letra en mayúscula.
        local wall_desc = S(pretty_name .. " Wall")

        -- 3. Guardar el bloque base para que los muros se conecten a él más tarde.
        table.insert(base_blocks_for_connection, material_node)

        -- 4. Registrar el nuevo nodo de muro.
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

        -- 5. Añadir el grupo "wall" para que la lógica de conexión funcione.
        local groups = minetest.registered_nodes[wall_name].groups
        groups.wall = 1
        minetest.override_item(wall_name, {groups = groups})

        -- 6. Registrar la receta de crafteo.
        minetest.register_craft({
            output = wall_name .. " 6",
            recipe = {
                {material_node, material_node, material_node},
                {material_node, material_node, material_node},
            }
        })

        minetest.log("action", "[wally] Muro creado para '" .. material_node .. "' -> '" .. wall_name .. "'")
    else
        -- minetest.log("warning", "[wally] Bloque de la lista blanca no encontrado, se ignora: " .. material_node)
    end
end


-- ===================================================================
-- >>>>>      MODIFICACIÓN DE XPANES (MÉTODO SIMPLE Y DIRECTO)   <<<<<
-- ===================================================================
-- (Esta sección se mantiene sin cambios)
if minetest.get_modpath("xpanes") then
    minetest.after(0, function()
        if minetest.registered_nodes["xpanes:bar_flat"] then
            minetest.override_item("xpanes:bar_flat", {
                on_place = function(itemstack, placer, pointed_thing)
                    if pointed_thing.type ~= "node" then return itemstack end
                    local pos = pointed_thing.above
                    local returned_itemstack = minetest.item_place(itemstack, placer, pointed_thing)
                    minetest.swap_node(pos, {name = "xpanes:bar", param2 = 0})
                    return returned_itemstack
                end
            })
            minetest.log("action", "[wally] 'xpanes:bar_flat' modificado para colocar un poste (método simple).")
        end

        if minetest.registered_nodes["xpanes:pane_flat"] then
            minetest.override_item("xpanes:pane_flat", {
                on_place = function(itemstack, placer, pointed_thing)
                    if pointed_thing.type ~= "node" then return itemstack end
                    local pos = pointed_thing.above
                    local returned_itemstack = minetest.item_place(itemstack, placer, pointed_thing)
                    minetest.swap_node(pos, {name = "xpanes:pane", param2 = 0})
                    return returned_itemstack
                end
            })
            minetest.log("action", "[wally] 'xpanes:pane_flat' modificado para colocar un poste (método simple).")
        end
    end)
end


-- ===================================================================
-- >>>>> BUCLE FINAL DE CONEXIÓN UNIVERSAL (TODO EN UNO)       <<<<<
-- ===================================================================

minetest.register_on_mods_loaded(function()
    -- >>>>> LISTA DE CONEXIONES PARA MUROS <<<<<
    -- Se conecta a otros muros, paneles y a todos los bloques base de la lista blanca.
    local wall_connects_to = {
        "group:wall", "group:pane", "group:glass",
        "group:stone", "group:sand", -- Grupos genéricos para mayor compatibilidad
        -- Lámparas y cristales de darkage
        "darkage:lamp", "darkage:glow_glass", "darkage:glow_glass_square", 
        "darkage:glow_glass_round", "darkage:glass_square",
    }
    
    -- Añadimos dinámicamente todos los bloques base a la lista de conexiones.
    for _, block_name in ipairs(base_blocks_for_connection) do
        table.insert(wall_connects_to, block_name)
    end
    
    -- >>>>> LISTA DE CONEXIONES PARA VALLAS DE MADERA <<<<<
    -- (Esta sección se mantiene sin cambios)
    local fence_connects_to = {
        "group:fence", "group:pane", "group:glass",
        "group:wood", "group:tree",
        "darkage:lamp", "darkage:glow_glass", "darkage:glow_glass_square", 
        "darkage:glow_glass_round", "darkage:glass_square",
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
                connects_to = wall_connects_to
            })
        end
    end
    
    minetest.log("action", "[wally] Conexiones universales aplicadas a muros y vallas.")
end)

