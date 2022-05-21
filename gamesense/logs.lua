local images = require 'gamesense/images'

local function contains(b,c)for d,e in pairs(b)do if e==c then return true end end;return false end
local function set_table(b,c,d)for e,f in pairs(c)do if type(f)=='table'then set_table(b,f,d)else b(f,d)end end end
function renderer.outline(x, y, w, h, r, g, b, a) renderer.rectangle(x - 1, y - 1, w + 2, 1, r, g, b, a) renderer.rectangle(x - 1, y + h, w + 2, 1, r, g, b, a) renderer.rectangle(x - 1, y, 1, h, r, g, b, a) renderer.rectangle(x + w, y, 1, h, r, g, b, a) end
function math.clamp(a, b, c)return math.min(math.max(a, b), c)end

local icons = {
    info = images.get_panorama_image('icons/ui/info.svg'),
    error = images.get_panorama_image('icons/ui/warning.svg'),
    miss = images.get_panorama_image('hud/deathnotice/icon_suicide.svg'),
    buy = images.get_panorama_image('icons/ui/inventory.svg'),
    hit = images.get_panorama_image('icons/ui/deathmatch.svg'),
}

local sizes = {}
for i, v in pairs(icons) do
    local i_w, i_h = v:measure();
    sizes[i] = { w = i_w, h = i_h }
end

local colorful_text = {
    lerp = function(self, from, to, duration)
        if type(from) == 'table' and type(to) == 'table' then
            return { 
                self:lerp(from[1], to[1], duration), 
                self:lerp(from[2], to[2], duration), 
                self:lerp(from[3], to[3], duration) 
            };
        end
    
        return from + (to - from) * duration;
    end,
    console = function(self, ...)
        for i, v in ipairs({ ... }) do
            if type(v[1]) == 'table' and type(v[2]) == 'table' and type(v[3]) == 'string' then
                for k = 1, #v[3] do
                    local l = self:lerp(v[1], v[2], k / #v[3]);
                    client.color_log(l[1], l[2], l[3], v[3]:sub(k, k) .. '\0');
                end
            elseif type(v[1]) == 'table' and type(v[2]) == 'string' then
                client.color_log(v[1][1], v[1][2], v[1][3], v[2] .. '\0');
            end
        end
    end,
    text = function(self, ...)
        local menu = false;
        local alpha = 255
        local f = '';
        
        for i, v in ipairs({ ... }) do
            if type(v) == 'boolean' then
                menu = v;
            elseif type(v) == 'number' then
                alpha = v;
            elseif type(v) == 'string' then
                f = f .. v;
            elseif type(v) == 'table' then
                if type(v[1]) == 'table' and type(v[2]) == 'string' then
                    f = f .. ('\a%02x%02x%02x%02x'):format(v[1][1], v[1][2], v[1][3], alpha) .. v[2];
                elseif type(v[1]) == 'table' and type(v[2]) == 'table' and type(v[3]) == 'string' then
                    for k = 1, #v[3] do
                        local g = self:lerp(v[1], v[2], k / #v[3])
                        f = f .. ('\a%02x%02x%02x%02x'):format(g[1], g[2], g[3], alpha) .. v[3]:sub(k, k)
                    end
                end
            end
        end
    
        return ('%s\a%s%02x'):format(f, (menu) and 'cdcdcd' or 'ffffff', alpha);
    end,
    log = function(self, ...)
        for i, v in ipairs({ ... }) do
            if type(v) == 'table' then
                if type(v[1]) == 'table' then
                    if type(v[2]) == 'string' then
                        self:console({ v[1], v[1], v[2] })
                        if (v[3]) then
                            self:console({ { 255, 255, 255 }, '\n' })
                        end
                    elseif type(v[2]) == 'table' then
                        self:console({ v[1], v[2], v[3] })
                        if v[4] then
                            self:console({ { 255, 255, 255 }, '\n' })
                        end
                    end
                elseif type(v[1]) == 'string' then
                    self:console({ { 205, 205, 205 }, v[1] });
                    if v[2] then
                        self:console({ { 255, 255, 255 }, '\n' })
                    end
                end
            end
        end
    end
}

local notify = {
    add = function(self, type, ...)
        table.insert(self.items, {
            ['text'] = table.concat({...}, ''),
            ['time'] = self.time,
            ['type'] = type or 'info',
            ['a'] = 255.0,
        });
    end,
    setup = function(self, data)
        self.max_logs = data.max_logs or 10
        self.position = data.position or { 8, 5 }
        self.time = data.time or 8.0
        self.images = data.images or false
        self.center_screen = data.center_screen or false
        self.center_additive = data.center_additive or 0
        self.simple = data.simple or false
        self.items = self.items or {}
    end,
    think = function(self)
        if #self.items <= 0 then return end
        if #self.items > self.max_logs then
            table.remove(self.items, 1);
        end

        for i, v in ipairs(self.items) do
            v.time = v.time - globals.frametime();
            if v.time <= 0 then
                table.remove(self.items, i);
            end
        end

        local s_w, s_h = client.screen_size();
        local c_w, c_h = s_w * 0.5, s_h * 0.5;

        local x, y, w, h, offset = 0, 0, 0, 0, { 5, 2 }
        local image_offset = 0;
        local text = ''
        local f = 0.0

        if (self.images) then
            offset[2] = 8;
            image_offset = 25;
        end

        if self.simple then
            offset = { 0, 0 }
            image_offset = 0;
        end

        local scale = 0.65

        if self.center_screen then
            x, y = c_w, c_h + 35 + self.center_additive;
            for i = #self.items, 1, -1 do
                local v = self.items[i]

                local text = string.gsub(v.text, '(%x%x%x%x%x%x%x%x)', function(hex) 
                    return ('%s%02x'):format(string.sub(hex, 1, -3), v.a); 
                end):gsub(' ', '  '):upper();
    
                local w, h = renderer.measure_text('cd-', text);
        
                local f = v.time;
                if (f < 0.5) then
                    math.clamp(f, 0.0, 0.5);
    
                    f = f / 0.5;
        
                    v.a = 255.0 * f;
        
                    if (i == 1 and f < 0.3) then
                        y = y + (h * (1.0 - f / 0.3));
                    end
                end
    
                if not self.simple then
                    renderer.rectangle(x - (w * 0.5), y, w + offset[1] * 2 + image_offset, h + offset[2] * 2, 20, 20, 20, v.a);
                    renderer.outline(x - (w * 0.5), y, w + offset[1] * 2 + image_offset, h + offset[2] * 2, 0, 0, 0, v.a);
                    renderer.rectangle(x - (w * 0.5), y + 1, w + offset[1] * 2 + image_offset, 1, 0, 0, 0, v.a);
                    renderer.gradient(x - (w * 0.5), y, math.min(w, w * (v.time / self.time)) + offset[1] * 2 + image_offset, 1, 255, 33, 137, v.a, 161, 80, 240, v.a, true);
                    if self.images then
                        icons[v.type]:draw(x - (w * 0.5) + offset[1], y + offset[2] * 0.5, sizes[v.type].w * scale, sizes[v.type].h * scale, 255, 255, 255, math.abs(math.cos(globals.realtime()))*v.a);
                    end
                end

                local text_pos = { x + offset[1] + image_offset, y + (h * 0.5) +  offset[2] }
                if self.simple then
                    text_pos = { x, y }
                end

                renderer.text(text_pos[1], text_pos[2], 255, 255, 255, v.a, 'cd-', 0, text);

                y = y + h + ((self.simple) and 0 or offset[2] * 2 + 5);
            end
        else
            x, y = self.position[1], self.position[2]
            for i, v in ipairs(self.items) do
                local text = string.gsub(v.text, '(%x%x%x%x%x%x%x%x)', function(hex) 
                    return ('%s%02x'):format(string.sub(hex, 1, -3), v.a); 
                end);
    
                local w, h = renderer.measure_text('d', text);
        
                local f = v.time;
                if (f < 0.5) then
                    math.clamp(f, 0.0, 0.5);
    
                    f = f / 0.5;
        
                    v.a = 255.0 * f;
        
                    if (i == 1 and f < 0.3) then
                        y = y - (h * (1.0 - f / 0.3));
                    end
                end
    
                if not self.simple then
                    renderer.rectangle(x, y, w + offset[1] * 2 + image_offset, h + offset[2] * 2, 20, 20, 20, v.a);
                    renderer.outline(x, y, w + offset[1] * 2 + image_offset, h + offset[2] * 2, 0, 0, 0, v.a);
                    renderer.rectangle(x, y + 1, w + offset[1] * 2 + image_offset, 1, 0, 0, 0, v.a);
                    renderer.gradient(x, y, math.min(w, w * (v.time / self.time)) + offset[1] * 2 + image_offset, 1, 255, 33, 137, v.a, 161, 80, 240, v.a, true);
                    if self.images then
                        icons[v.type]:draw(x + offset[1], y + offset[2] * 0.5, sizes[v.type].w * scale, sizes[v.type].h * scale, 255, 255, 255, math.abs(math.cos(globals.realtime()))*v.a);
                    end
                end

                local text_pos = { x + offset[1] + image_offset, y + offset[2] }
                if self.simple then
                    text_pos = { x, y }
                end

                renderer.text(text_pos[1], text_pos[2], 255, 255, 255, v.a, 'd', 0, text);

                y = y + h + ((self.simple) and 0 or offset[2] * 2 + 5);
            end
        end
    end
}

local items = {
    colorful_text:text(true, { { 255, 33, 137 }, { 161, 80, 240 }, "aimbot miss" } ), 
    colorful_text:text(true, { { 255, 33, 137 }, { 161, 80, 240 }, "damage given" } ), 
    colorful_text:text(true, { { 255, 33, 137 }, { 161, 80, 240 }, "damage received" } ), 
    colorful_text:text(true, { { 255, 33, 137 }, { 161, 80, 240 }, "weapon purchase" } ),
}

local menu = {
    main = ui.new_checkbox("RAGE", "Aimbot", "[" .. colorful_text:text(true, { { 255, 33, 137 }, { 161, 80, 240 }, "myzarlogs" } ) .. "] enabled"),
    entries = {
        options = ui.new_multiselect("RAGE", "Aimbot", "\noptions", items),
        max_logs = ui.new_slider("RAGE", "Aimbot", colorful_text:text(true, { { 161, 80, 240 }, " > " } ) .. "max logs", 9, 20, 0, true, "", 1, {[9] = "∞"}),
        simple_logs = ui.new_checkbox("RAGE", "Aimbot", colorful_text:text(true, { { 161, 80, 240 }, " > " } ) .. "simple logs"),
        render_images = ui.new_checkbox("RAGE", "Aimbot", colorful_text:text(true, { { 161, 80, 240 }, " > " } ) .. "render images"),
        crosshair_logs = ui.new_checkbox("RAGE", "Aimbot", colorful_text:text(true, { { 161, 80, 240 }, " > " } ) .. "crosshair logs"),
        crosshair_additive = ui.new_slider("RAGE", "Aimbot", colorful_text:text(true, { { 161, 80, 240 }, " > " } ) .. "additive", 0, 100, 0),
    }
}

local ref = {
    log_weapon_purchases = ui.reference('MISC', 'Miscellaneous', 'Log weapon purchases'),
    log_damage_dealt = ui.reference('MISC', 'Miscellaneous', 'Log damage dealt'),
    log_misses_due_to_spread = ui.reference('RAGE', 'Aimbot', 'Log misses due to spread'),
    hitchance = ui.reference('RAGE', 'Aimbot', 'Minimum hit chance'),
    min_dmg = ui.reference('RAGE', 'Aimbot', 'Minimum damage'),
    legit_enabled = ui.reference('LEGIT', 'Aimbot', 'Enabled'),
    values = {
        log_weapon_purchases = false,
        log_damage_dealt = false,
        log_misses_due_to_spread = false,
        render_images = false,
    }
}

local vars = {
    local_player = 0,
    hitgroup_names = { 'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear' }
}

local on_paint_ui = function()
    notify:think();
end

local on_aim_miss = function(data)
    if not contains(ui.get(menu.entries.options), items[1]) then return end

    if data.reason == "death" then
        if vars.local_player:is_alive() then
            data.reason = "player death"
        else
            data.reason = "local death"
        end
    end

    if data.reason == "prediction error" then
        data.reason = "prediction"
    end

    if data.reason == "?" then
        data.reason = "resolver"
    end

    local ping = math.min(999, client.real_latency() * 1000)
    local ping_col = (ping >= 100) and { 255, 0, 0 } or { 150, 200, 60 }

    local hc = math.floor(data.hit_chance + 0.5);
    local hc_col = (hc < ui.get(ref.hitchance)) and { 255, 0, 0 } or { 150, 200, 60 };

    colorful_text:log(
        { { 255, 33, 137 }, { 161, 80, 240 }, "[myzarlogs] " },
        { { 205, 205, 205 }, ("missed %s's %s due to "):format(entity.get_player_name(data.target), vars.hitgroup_names[data.hitgroup + 1] or '?') },
        { { 255, 0, 0 }, ("%s"):format((data.reason == '?' and 'resolver' or data.reason)) },
        { { 205, 205, 205 }, ". [ rtt: "},
        { ping_col, ("%dms"):format(ping) },
        { { 205, 205, 205 }, " | ang: " },
        { { 255, 33, 137 }, ("%d"):format(math.floor( entity.get_prop(data.target, 'm_flPoseParameter', 11 ) * 120 - 60 )) },
        { { 205, 205, 205 }, " | hc: "},
        { hc_col, ("%d%%"):format(hc) },
        { { 205, 205, 205 }, " ]", true }
    );

    notify:add(
        "miss",
        colorful_text:text({ { 255, 255, 255 }, ("missed %s's %s due to "):format(entity.get_player_name(data.target), vars.hitgroup_names[data.hitgroup + 1] or '?') }),
        colorful_text:text({ { 255, 0, 0 }, ("%s"):format((data.reason == '?' and 'resolver' or data.reason))}),
        colorful_text:text({ { 255, 255, 255 }, ". [ rtt: "}),
        colorful_text:text({ ping_col, ("%dms"):format(ping) }),
        colorful_text:text({ { 255, 255, 255 }, " | ang: " }),
        colorful_text:text({ { 255, 33, 137 }, ("%d"):format(math.floor( entity.get_prop(data.target, 'm_flPoseParameter', 11 ) * 120 - 60 )) }),
        colorful_text:text({ { 255, 255, 255 }, " | hc: "}),
        colorful_text:text({ hc_col, ("%d%%"):format(hc) }),
        colorful_text:text({ { 255, 255, 255 }, " ]" })
    );
end

local on_item_purchase = function(event)
    if not contains(ui.get(menu.entries.options), items[4]) then return end

    local userid = event.userid
    if userid == nil then return end

    if event.team == entity.get_prop(vars.local_player, 'm_iTeamNum') then return end

    local buyer = client.userid_to_entindex(userid)
    if buyer == nil then return end

    if event.weapon == "weapon_unknown" then return end

    local item = event.weapon;
    item = item:gsub('weapon_', '')

    if item == 'item_assaultsuit' then
        item = 'kevlar + helmet'
    elseif item == 'item_kevlar' then
        item = 'kevlar'
    elseif item == 'item_defuser' then
        item = 'defuser'
    else
        item = item:gsub('grenade', ' grenade');
    end

    colorful_text:log(
        { { 255, 33, 137 }, { 161, 80, 240 }, "[myzarlogs] " },
        { { 205, 205, 205 }, ("%s purchased "):format(entity.get_player_name(buyer)) },
        { { 255, 0, 0 }, ("%s"):format(item) },
        { { 205, 205, 205 }, ".", true }
    )

    notify:add(
        "buy",
        colorful_text:text({ { 255, 255, 255 }, ("%s purchased "):format(entity.get_player_name(duder))}),
        colorful_text:text({ { 255, 0, 0 }, ("%s"):format(item) }),
        colorful_text:text({ { 255, 255, 255 }, "." })
    );
end

local on_player_hurt = function(event)
    local victim_idx, attacker_idx = event.userid, event.attacker
	if victim_idx == nil or attacker_idx == nil then
		return
	end

    local dmg_color = (ui.get(ref.min_dmg) <= event.dmg_health and not ui.get(ref.legit_enabled)) and { 150, 200, 60 } or { 255, 0, 0 }
    local baimable = (ui.get(ref.min_dmg) <= event.health and not ui.get(ref.legit_enabled)) and { 150, 200, 60 } or { 255, 0, 0 }

    local victim, attacker = client.userid_to_entindex(victim_idx), client.userid_to_entindex(attacker_idx)
    if attacker ~= vars.local_player or victim == vars.local_player then 
        if (victim == vars.local_player and attacker ~= vars.local_player) then
            if contains(ui.get(menu.entries.options), items[3]) then
                local attacker_name = entity.get_player_name(attacker)
                if attacker_name == 'unknown' then return end

                colorful_text:log(
                    { { 255, 33, 137 }, { 161, 80, 240 }, "[myzarlogs] " },
                    { { 205, 205, 205 }, ("harmed by %s in the %s for "):format(attacker_name, vars.hitgroup_names[event.hitgroup + 1] or '?') },
                    { { 160, 200, 50 }, ("%s"):format(event.dmg_health) },
                    { { 205, 205, 205 }, ".", true}
                );

                notify:add(
                    "error",
                    colorful_text:text({ { 255, 255, 255 }, ("harmed by %s in the %s for "):format(attacker_name, vars.hitgroup_names[event.hitgroup + 1] or '?') }),
                    colorful_text:text({ { 160, 200, 50 }, ("%s"):format(event.dmg_health) }),
                    colorful_text:text({ { 255, 255, 255 }, "." })
                );
            end
        end
        return
    end

    if contains(ui.get(menu.entries.options), items[2]) then 
        colorful_text:log(
            { { 255, 33, 137 }, { 161, 80, 240 }, "[myzarlogs] " },
            { { 205, 205, 205 }, ("hit %s's %s for "):format(entity.get_player_name(victim), vars.hitgroup_names[event.hitgroup + 1] or '?') },
            { dmg_color, ("%s"):format(event.dmg_health) },
            { { 205, 205, 205 }, ". ( " },
            { baimable, ("%s"):format(event.health) },
            { { 205, 205, 205 }, " health remaining )", true }
        );

        notify:add(
            "hit",
            colorful_text:text({ { 255, 255, 255 }, ("hit %s's %s for "):format(entity.get_player_name(victim), vars.hitgroup_names[event.hitgroup + 1] or '?') }),
            colorful_text:text({ dmg_color, ("%s"):format(event.dmg_health) }),
            colorful_text:text({ { 255, 255, 255 }, ". ( " }),
            colorful_text:text({ baimable, ("%s"):format(event.health) }),
            colorful_text:text({ { 255, 255, 255 }, " health remaining )" })
        );
    end
end

local on_setup_command = function(cmd)
    vars.local_player = entity.get_local_player();
end 

local on_load = function(state)
    local func = (state) and client.set_event_callback or client.unset_event_callback

    set_table(ui.set_visible, { ref.log_weapon_purchases, ref.log_damage_dealt, ref.log_misses_due_to_spread }, not state);
    if not state then
        ui.set(ref.log_weapon_purchases, ref.values.log_weapon_purchases);
        ui.set(ref.log_damage_dealt, ref.values.log_damage_dealt);
        ui.set(ref.log_misses_due_to_spread, ref.values.log_misses_due_to_spread);
    else
        set_table(ui.set, { ref.log_weapon_purchases, ref.log_damage_dealt, ref.log_misses_due_to_spread }, false);
    end

    set_table(ui.set_visible, { menu.entries }, state);
    ui.set_visible(menu.entries.render_images, not ui.get(menu.entries.simple_logs) and state);
    ui.set_visible(menu.entries.crosshair_additive, ui.get(menu.entries.crosshair_logs) and state)

    func("paint_ui", on_paint_ui);
    func("item_purchase", on_item_purchase);
    func("player_hurt", on_player_hurt);
    func("setup_command", on_setup_command);
    func("aim_miss", on_aim_miss);

    local max_logs = ui.get(menu.entries.max_logs);
    if max_logs == 9 then
        max_logs = 115;
    end

    notify:setup({ max_logs = max_logs, images = ui.get(menu.entries.render_images), center_screen = ui.get(menu.entries.crosshair_logs), simple = ui.get(menu.entries.simple_logs), center_additive = ui.get(menu.entries.crosshair_additive) });
end

ui.set_callback(menu.main, function()
    local state = ui.get(menu.main);
    on_load(state)
end)

ui.set_callback(menu.entries.max_logs, function()
    local value = ui.get(menu.entries.max_logs);
    if (value == 9) then
        value = 115;
    end

    notify:setup({ max_logs = value, images = ui.get(menu.entries.render_images), center_screen = ui.get(menu.entries.crosshair_logs), simple = ui.get(menu.entries.simple_logs), center_additive = ui.get(menu.entries.crosshair_additive) });
end)

ui.set_callback(menu.entries.render_images, function()
    local state = ui.get(menu.entries.render_images)
    local max_logs = ui.get(menu.entries.max_logs);
    if max_logs == 9 then
        max_logs = 115;
    end

    notify:setup({ max_logs = max_logs, images = state, center_screen = ui.get(menu.entries.crosshair_logs), simple = ui.get(menu.entries.simple_logs), center_additive = ui.get(menu.entries.crosshair_additive) });
end)

ui.set_callback(menu.entries.crosshair_logs, function()
    local state = ui.get(menu.entries.crosshair_logs)
    local max_logs = ui.get(menu.entries.max_logs);
    if max_logs == 9 then
        max_logs = 115;
    end

    set_table(ui.set_visible, { menu.entries.crosshair_additive }, state);

    notify:setup({ max_logs = max_logs, images = ui.get(menu.entries.render_images), center_screen = state, simple = ui.get(menu.entries.simple_logs), center_additive = ui.get(menu.entries.crosshair_additive) });
end)

ui.set_callback(menu.entries.simple_logs, function()
    local state = ui.get(menu.entries.simple_logs)
    local max_logs = ui.get(menu.entries.max_logs);
    if max_logs == 9 then
        max_logs = 115;
    end

    if (state) then
        ref.values.render_images = ui.get(menu.entries.render_images);
        ui.set(menu.entries.render_images, false);
        ui.set_visible(menu.entries.render_images, false);
    else
        ui.set(menu.entries.render_images, ref.values.render_images);
        ui.set_visible(menu.entries.render_images, true);
    end

    notify:setup({ max_logs = max_logs, images = ui.get(menu.entries.render_images), center_screen = ui.get(menu.entries.crosshair_logs), simple = state, center_additive = ui.get(menu.entries.crosshair_additive) });
end)

ui.set_callback(menu.entries.crosshair_additive, function()
    local value = ui.get(menu.entries.crosshair_additive);
    local max_logs = ui.get(menu.entries.max_logs);
    if max_logs == 9 then
        max_logs = 115;
    end

    notify:setup({ max_logs = max_logs, images = ui.get(menu.entries.render_images), center_screen = ui.get(menu.entries.crosshair_logs), simple = ui.get(menu.entries.simple_logs), center_additive = value });
end)

ref.values.log_weapon_purchases = ui.get(ref.log_weapon_purchases);
ref.values.log_damage_dealt = ui.get(ref.log_damage_dealt);
ref.values.log_misses_due_to_spread = ui.get(ref.log_misses_due_to_spread);

on_load(false);
