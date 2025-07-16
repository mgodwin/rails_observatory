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

-- Arguments:
-- ARGV[1]: metric_name (string)
-- ARGV[2]: timestamp (number) - Unix time (integer, in milliseconds)
-- ARGV[3], ARGV[4], ...: key-value pairs for labels (even indices are keys, odd indices are values)

-- Main script begins here
local metric_name = tostring(ARGV[1])
local timestamp = tonumber(ARGV[2])
local raw_retention = 10000 -- Hardcoded to 10ms
local compaction_retention = 31536000000 -- Hardcoded to 1 year in ms (365*24*60*60*1000)

-- Extracting labels
---@type table
local labels = {}
local keys = {}
for i = 3, #ARGV, 2 do
  local key = tostring(ARGV[i])
  local value = tostring(ARGV[i + 1])
  labels[key] = value
  redis.call("SADD", metric_name .. ':labels', key)
  table.insert(keys, key)
end

local key_combinations = generate_key_combinations(keys)

-- For each combination, upsert and add labels
for _, comb_keys in ipairs(key_combinations) do
  local ts_name = metric_name
  local label_set = {}

  for _, key in ipairs(comb_keys) do
    ts_name = ts_name .. ":" .. labels[key]
    table.insert(label_set, key)
    table.insert(label_set, labels[key])
  end

  if redis.call("EXISTS", ts_name) == 0 then
    redis.call("TS.CREATE", ts_name, "RETENTION", raw_retention, "CHUNK_SIZE", 48)
  end

  local compaction_key = ts_name .. "_" .. "sum"
  if redis.call("EXISTS", compaction_key) == 0 then
    redis.call("TS.CREATE", compaction_key, "RETENTION", compaction_retention, "CHUNK_SIZE", 48, "LABELS", "name", metric_name, "compaction", "sum", unpack(label_set))
    redis.call("TS.CREATERULE", ts_name, compaction_key, "AGGREGATION", "sum", 10000)
  end
  redis.call("TS.ADD", ts_name, timestamp, 1, 'ON_DUPLICATE', 'SUM')
end

return "OK"
