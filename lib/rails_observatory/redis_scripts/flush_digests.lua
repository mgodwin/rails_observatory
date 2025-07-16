-- flushes all tdigest keys in Redis to time series keys

local compaction_retention = 31536000000 -- Hardcoded to 1 year in ms (365*24*60*60*1000)

-- The 'tdigests' set contains the names of all tdigests that have been created since the last
-- flush operation. The format is di-metric_name?label1,value1,label2,value2...
local digests = redis.call("SMEMBERS", "tdigests")

-- Iterate through all digests and flush them to time series keys
for i, digest in ipairs(digests) do
  -- Extract the metric name and labels from the digest name
  local labels = {}
  local metric_name, label_set = string.match(digest, "^di%-([^?]+)%?(.*)$")

  local ts_name = metric_name
  for key,value in string.gmatch(label_set, "([^,]+),([^,]+)") do
    table.insert(labels, key)
    table.insert(labels, value)

    ts_name = ts_name .. ":" .. key
  end

  ts_name = ts_name .. "_p95"

  if redis.call("EXISTS", ts_name) == 0 then
    redis.call("TS.CREATE", ts_name, "RETENTION", compaction_retention, "CHUNK_SIZE", 48, "LABELS", "name", metric_name, "compaction", "p95", unpack(labels))
  end

  local percentile = redis.call("TDIGEST.QUANTILE", digest, 0.95)

  redis.call("TS.ADD", ts_name, "*", percentile[1])
  redis.call("SREM", "tdigests", digest)
end