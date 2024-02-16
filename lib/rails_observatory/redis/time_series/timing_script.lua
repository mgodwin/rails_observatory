-- Helper function to get all combinations of a table
local function generate_key_combinations(keys)
  local n = #keys
  local combs = {}
  table.insert(combs, {})

  local function helper(curr_comb, start_idx)
    if start_idx <= n then
      for i = start_idx, n do
        local new_comb = {}
        for _, v in ipairs(curr_comb) do
          table.insert(new_comb, v)
        end
        table.insert(new_comb, keys[i])
        table.insert(combs, new_comb)
        helper(new_comb, i + 1)
      end
    end
  end

  helper({}, 1)
  return combs
end

local function extract_parent_label(base_name)
  local index = string.find(base_name, "/")
  if index then
    return string.sub(base_name, 1, index - 1)
  else
    return nil
  end
end

-- Main script begins here
local metric_name = tostring(ARGV[1])  -- Ensure it's a string
local value_to_add = tonumber(ARGV[2]) -- Ensure it's a number
local raw_retention = 10000 -- Hardcoded to 10ms
local compaction_retention = 31536000000 -- Hardcoded to 1 year in ms (365*24*60*60*1000)
local compactions = { "avg", "min", "max" }

-- Assuming base_name is defined somewhere above
local parent_label = extract_parent_label(metric_name)

-- Extracting labels
local labels = {}
local keys = {}
for i = 3, #ARGV, 2 do
  local key = tostring(ARGV[i])
  local value = tostring(ARGV[i + 1])
  labels[key] = value
  if parent_label then
    redis.call("SADD", parent_label .. ':labels', key)
  else
    redis.call("SADD", metric_name .. ':labels', key)
  end
  table.insert(keys, key)
end

local key_combinations = generate_key_combinations(keys)

-- For each combination, upsert and add labels
for _, comb_keys in ipairs(key_combinations) do
  local ts_name = metric_name
  local label_set = {}

  if parent_label then
    table.insert(label_set, "parent")
    table.insert(label_set, parent_label)
  end

  for _, key in ipairs(comb_keys) do
    ts_name = ts_name .. ":" .. labels[key]
    table.insert(label_set, key)
    table.insert(label_set, labels[key])
  end

  if redis.call("EXISTS", ts_name) == 0 then
    redis.call("TS.CREATE", ts_name, "RETENTION", raw_retention, "CHUNK_SIZE", 48)
  end

  -- Handle the compactions (avg, min, max)
  for _, compaction in ipairs(compactions) do
    local compaction_key = ts_name .. "_" .. compaction
    if redis.call("EXISTS", compaction_key) == 0 then
      redis.call("TS.CREATE", compaction_key, "RETENTION", compaction_retention, "CHUNK_SIZE", 48, "LABELS", "name", metric_name, "compaction", compaction, unpack(label_set))
      redis.call("TS.CREATERULE", ts_name, compaction_key, "AGGREGATION", compaction, 10000)
    end
  end
  redis.call("TS.ADD", ts_name, "*", value_to_add)
end

return "OK"
