cjson = require 'cjson'

local redis_eval_str = [[

local function cmd(src, stack, i, structure, parent, parent_key)
    local a = stack[i]
    local b = stack[i-1]
    if src == ":GO" then
        if i < 1 then error("stack empty :GO") end
        return stack, i-1, structure[a], structure, a
    elseif src == ":MATCH" then
        if i < 2 then error("stack empty :MATCH") end
        -- reduces stack by two
        local key = b
        local val = a
        for idx,item in ipairs(structure) do
            if val == item[key] then
                stack[i-1] = nil
                stack[i] = nil
                return stack, i-2, structure[idx], structure, idx
            end
        end
        error("cannot match key "..tostring(key).." val "..tostring(val))
    elseif src == ":DEL" then
        if i < 1 then error("stack empty :DEL") end
        -- reduces stack by one
        if type(a) == "number" then
            table.remove(structure, a)
        elseif type(a) == "string" then
            structure[a] = nil
        end
        stack[i] = nil
        return stack, i-1, structure, parent, parent_key
    elseif src == ":DELX" then
        if type(parent_key) == "number" then
            table.remove(parent, parent_key)
        elseif type(parent_key) == "string" then
            parent[parent_key] = nil
        end
        return stack, i, structure, parent, parent_key
    elseif src == ":SET" then
        if i < 2 then error("stack empty :SET") end
        -- reduces stack by two
        structure[b] = a
        stack[i], stack[i-1] = nil, nil
        return stack, i-2, structure, parent, parent_key
    elseif src == ":APPEND" then
        if i < 1 then error("stack empty :APPEND") end
        -- reduces stack by one
        structure[#structure+1] = a
        stack[i] = nil
        return stack, i-1, structure, parent, parent_key
    elseif src == ":APPENDX" then
        if i < 1 then error("stack empty :APPEND") end
        -- reduces stack by one
        parent[#parent+1] = a
        stack[i] = nil
        return stack, i-1, structure, parent, parent_key
    else
        -- not a command - push a value
        local a = src
        if string.sub(a, 1, 1) == "{" or string.sub(a, 1, 1) == "[" then
            stack[i+1] = cjson.decode(a)
        else
            stack[i+1] = a
        end
        return stack, i+1, structure, parent, parent_key
    end
end

local root, parent, parent_key, obj, stack, stack_idx

local value = redis.call('get',KEYS[1])
if not value then
    value = "{}"
end
redis.log(redis.LOG_NOTICE, "Starting with:"..value)
redis.log(redis.LOG_NOTICE, "keys:"..KEYS[1])
root = cjson.decode(value)
obj, stack, stack_idx, parent, parent_key = root, {}, 0, nil

for i = 2,#KEYS do
    stack, stack_idx, obj, parent, parent_key = cmd(KEYS[i], stack, stack_idx, obj, parent, parent_key)
end

redis.log(redis.LOG_NOTICE, "Ended up with:"..cjson.encode(root))
redis.call('set',KEYS[1],cjson.encode(root))

]]

function atomic_redis (client, redis_key)
    local rd = {cmds = {redis_key}, client = client}
    local rd_mt = {
        __call = function(t, k)
            t.cmds[#t.cmds+1] = k
            t.cmds[#t.cmds+1] = ":GO"
            return t
        end
    }

    function rd.match (t, k, v)
        t.cmds[#t.cmds+1] = k
        t.cmds[#t.cmds+1] = v
        t.cmds[#t.cmds+1] = ":MATCH"
        return t
    end

    function rd.set (t, k, v)
        t.cmds[#t.cmds+1] = k
        if type(v) == "table" then
            v = cjson.encode(v)
        end
        t.cmds[#t.cmds+1] = v
        t.cmds[#t.cmds+1] = ":SET"
        t:_run()
        return t
    end

    function rd.append (t, v)
        t.cmds[#t.cmds+1] = v
        t.cmds[#t.cmds+1] = ":APPEND"
        t:_run()
        return t
    end

    function rd.del (t, v)
        if v then
            t.cmds[#t.cmds+1] = v
            t.cmds[#t.cmds+1] = ":DEL"
        else
            t.cmds[#t.cmds+1] = ":DELX"
        end
        t:_run()
        return t
    end

    function rd._run (t)
        t.client:eval(redis_eval_str, #t.cmds, unpack(t.cmds))
        t.cmds = {redis_key}
    end
    setmetatable(rd, rd_mt)
    return rd
end

return atomic_redis
