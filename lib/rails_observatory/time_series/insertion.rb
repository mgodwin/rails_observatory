require 'benchmark'

SCRIPT = <<~LUA
  -- Helper function to create a time series key
  local function ts_key(name, labels_table)
      local key_parts = {name}
      for _, v in pairs(labels_table) do
          table.insert(key_parts, tostring(v))  -- Ensure it's a string
      end
      return table.concat(key_parts, ":")
  end

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

  -- Main script begins here
  local metric_name = tostring(ARGV[1])  -- Ensure it's a string
  local value_to_add = tonumber(ARGV[2]) -- Ensure it's a number
  local raw_retention = 10000 -- Hardcoded to 10ms
  local compaction_retention = 31536000000 -- Hardcoded to 1 year in ms (365*24*60*60*1000)
  local compactions = {"avg", "min", "max"}

  -- Extracting labels
  local labels = {}
  local keys = {}
  for i=3, #ARGV, 2 do
      local key = tostring(ARGV[i])
      local value = tostring(ARGV[i+1])
      labels[key] = value
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
          redis.call("TS.CREATE", ts_name, "RETENTION", raw_retention)
      end
      
      -- Handle the compactions (avg, min, max)
      for _, compaction in ipairs(compactions) do
          local compaction_key = ts_name .. "_" .. compaction
          if redis.call("EXISTS", compaction_key) == 0 then
              redis.call("TS.CREATE", compaction_key, "RETENTION", compaction_retention, "LABELS","name", metric_name, "compaction", compaction, unpack(label_set))
              redis.call("TS.CREATERULE", ts_name, compaction_key, "AGGREGATION", compaction, compaction_retention)
          end
      end
      redis.call("TS.ADD", ts_name, "*", value_to_add)
  end

  return "OK"
LUA

INCREMENT_SCRIPT = <<~LUA
  -- Helper function to create a time series key
  local function ts_key(name, labels_table)
      local key_parts = {name}
      for _, v in pairs(labels_table) do
          table.insert(key_parts, tostring(v))  -- Ensure it's a string
      end
      return table.concat(key_parts, ":")
  end

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

  -- Main script begins here
  local metric_name = tostring(ARGV[1])  -- Ensure it's a string
  local raw_retention = 10000 -- Hardcoded to 10ms
  local compaction_retention = 31536000000 -- Hardcoded to 1 year in ms (365*24*60*60*1000)
  local compactions = {"sum"}

  -- Extracting labels
  local labels = {}
  local keys = {}
  for i=2, #ARGV, 2 do
      local key = tostring(ARGV[i])
      local value = tostring(ARGV[i+1])
      labels[key] = value
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
          redis.call("TS.CREATE", ts_name, "RETENTION", raw_retention)
      end
      
      -- Handle the compactions (avg, min, max)
      for _, compaction in ipairs(compactions) do
          local compaction_key = ts_name .. "_" .. compaction
          if redis.call("EXISTS", compaction_key) == 0 then
              redis.call("TS.CREATE", compaction_key, "RETENTION", compaction_retention, "LABELS", "name", metric_name, "compaction", compaction, unpack(label_set))
              redis.call("TS.CREATERULE", ts_name, compaction_key, "AGGREGATION", compaction, 10000)
          end
      end
      redis.call("TS.ADD", ts_name, "*", 1, 'ON_DUPLICATE', 'SUM')
  end

  return "OK"
LUA


class RedisScript
  def initialize(lua_string)
    @script = lua_string
  end

  def call(*args)
    @sha1 ||= load_script
    $redis.call("EVALSHA", @sha1, 0, *args)
  rescue => e
    if e.message =~ /NOSCRIPT/
      @sha1 = load_script
      retry
    else
      raise e
    end
  end

  def load_script
    $redis.call('SCRIPT', 'LOAD', @script)
  end

end

TIMING_SCRIPT = RedisScript.new(SCRIPT)
INCREMENT_CALL = RedisScript.new(INCREMENT_SCRIPT)



module RailsObservatory
  module TimeSeries::Insertion
    def timing(name, value, labels: {})
      TIMING_SCRIPT.call(name, value, labels.to_a.flatten.map(&:to_s))
    end

    def increment(name, labels: {})
      INCREMENT_CALL.call(name, labels.to_a.flatten.map(&:to_s))
    end
  end
end