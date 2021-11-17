--

local fmt, cat, sort = string.format, table.concat, table.sort

local print, select, pairs, pcall, type, tostring = 
      print, select, pairs, pcall, type, tostring

local function hashByKeys(itemTemplate, nonil)
  if type(itemTemplate)~='table'then error('item template has to be type table')end
  local keys = {}  
  for k in pairs(itemTemplate)do keys[1+#keys]=k end
  sort(keys, function(a,b)-- get unique keys list
    local ok, cmp = pcall(function()return a < b end)
    if ok then return cmp end
    local ta, tb = type(a), type(b)
    if ta~=tb then -- order different types
      return ta < tb 
    elseif ta =='number' or ta == 'string'then-- ordered primitive
      return a < b
    else -- eg, false < true ; table<0x1234> < table<0x5678> etc.
      return tostring(a)<tostring(b)
    end    
  end)
  return function(itm) -- itm can be table/userdata, indexable
    local hash = {}
    for i=1,#keys do 
      local v = itm[keys[i]]
      if nonil and v==nil then error('expected non nil value on key: '.. keys[i],2) end
      hash[i] = type(v)=='string' and fmt('%q',v)or tostring(v)
    end
    return cat(hash,';')   
  end  
end


local function ustack(uhash) -- uhash(itm) should return non-numeric as hash
  local top, stack = 0, {}
  local function getTop()
    local itm
    while top>0 do
      itm = stack[top]
      if itm~=nil then break else top = top - 1 end
    end
    return top, itm
  end
  local function contain(itm) 
    local ok, hash = pcall(uhash,itm)
    if not ok then return nil, hash, itm end    
    local idx = stack[hash]
    return idx~=nil, hash, idx, itm
  end
  local function remove(itm)
    local contained, hash, idx = contain(itm)    
    if contained==nil then -- not hashable/error
      return nil, hash -- hash == error msg
    elseif not contained  then -- == false
      return false,'no such itm',itm
    else
      stack[idx], stack[hash] = nil -- remove itm in array/dict part 
      return true, itm 
    end
  end  
  local function push(itm)    
    local contained, hash, idx = contain(itm)
    if contained == nil then 
      return nil, hash -- hash == error msg
    elseif not contained then
      top = getTop()+1
      stack[top], stack[hash] = itm, top
      return true, itm
    else
      return false, itm
    end      
  end    
  local function pop()
    local _, itm = getTop()
    if itm then remove(itm) return itm else return nil,'stack empty' end
  end    
  return {
    contain = contain,
    getTop = getTop,
    remove = remove,
    push = push,
    pop = pop,     
  }  
end
if ... then return {ustack=ustack, hashByKeys = hashByKeys} end-- return as module if required
---   test
local NULL = {}
local hash = hashByKeys({1,2,3},true)-- test itm use array of string/num so to easier output with table.concat
local stack = ustack(hash)

local function show(...)
  local n, p, out = select('#',...),{...},{}
  for i=1,n do 
    local v = p[i]
    out[1+#out] = type(v)=='table' and '{ '..table.concat(v,', ')..' }' or tostring(v)
  end  
  --out[1+#out] = ' --- ' .. stack.show()
  print(cat(out,'\t'))
end
show('push',stack.push{2,'xxx',456})
show('push',stack.push{2,'xxx',789})
show('push',stack.push{2,'xxx',456})
show('push',stack.push{2,'xxx',111})
show('push',stack.push{2,'xxx',222})
show('push',stack.push{2,'xxx',333})
show('remove',stack.remove{2,'xxx',456})
show('remove',stack.remove{2,'xxx',111})
show('peek top',stack.getTop())
show('pop',stack.pop())
show('pop',stack.pop())
show('pop',stack.pop())
show('pop',stack.pop())
show('remove',stack.remove{nil,'xxx',111})-- nil entry return error msg in this test
