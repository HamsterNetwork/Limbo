local ui = {}
ui.callbacks_t = {}

ui_item_t = {
    label = '',
    type = '',
    items = nil
}

function search_table_index(tbl, value)
    for i = 1, #tbl do
        if tbl[i] == value then
            return i
        end
    end
    return nil
end

function ui_item_t:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function ui_item_t:get_type()
    return self.type
end

function ui_item_t:set_type(t)
    self.type = t
end

function ui_item_t:get()
    local t = self:get_type()

    if t == 'int' then
        return menu.get_int(self.label)
    elseif t == 'combo' then
        return (self.items and self.items[menu.get_int(self.label) + 1] or menu.get_int(self.label) + 1)
    elseif t == 'color' then
        return menu.get_color(self.label)
    elseif t == 'bool' then
        return menu.get_bool(self.label)
    elseif t == 'float' then
        return menu.get_float(self.label)
    elseif t == 'key' then
        return {menu.get_key_bind_state(self.label), menu.get_key_bind_mode(self.label)}
    end
    return nil
end

function ui_item_t:set(v)
    local t = self:get_type()

    if t == 'int' or t == 'float' then
        menu.set_int(self.label, tonumber(v))
    elseif t == 'combo' then
        menu.set_int(self.label, (search_table_index(self.items or {}, v) or tonumber(v)) - 1)
    elseif t == 'color' then
        menu.set_color(self.label, v)
    elseif t == 'bool' then
        menu.set_bool(self.label, v)
    end
end

function ui_item_t:get_list()
    if t == 'combo' then
        return self.items
    end
end

function ui_item_t:locate()
    return self.label
end

function ui_item_t:set_callback(func)
    ui.callbacks_t[self.label] = func
end

function ui_item_t:unset_callback(func)
    ui.callbacks_t[self.label] = nil
end

ui.get = function(ui_item)
    return ui_item:get()
end

ui.set = function(ui_item, v)
    ui_item:set(v)
end

ui.switch = function(label)
    local var = ui_item_t:new()
    var.label = label
    var.type = 'bool'
    menu.add_check_box(label)
    return var
end

ui.combo = function(label, items)
    local var = ui_item_t:new()
    var.label = label
    var.type = 'combo'
    var.items = items
    menu.add_combo_box(label, items)
    return var
end

ui.keybind = function(label)
    local var = ui_item_t:new()
    var.label = label
    var.type = 'key'
    menu.add_key_bind(label)
    return var
end

ui.slider_int = function(label, min, max)
    local var = ui_item_t:new()
    var.label = label
    var.type = 'int'
    menu.add_slider_int(label, min, max)
    return var
end

ui.slider_float = function(label, min, max)
    local var = ui_item_t:new()
    var.label = label
    var.type = 'float'
    menu.add_slider_float(label, min, max)
    return var
end

ui.color_picker = function(label)
    local var = ui_item_t:new()
    var.label = label
    var.type = 'color'
    menu.add_color_picker(label)
    return var
end

ui.ref = function(ref, type)
    local var = ui_item_t:new()
    var.label = ref
    var.type = type
    return var
end

ui.run = function()
    for k, v in pairs(ui.callbacks_t) do
        local func = ui.callbacks_t[k]
        if func ~= nil and type(func) == 'function' then
            func()
        end
    end

end

return ui
