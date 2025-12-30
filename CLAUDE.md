# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Rails Observatory is a Rails engine gem that provides APM (Application Performance Monitoring) capabilities for Rails applications. It hooks into ActiveSupport::Notifications to capture traces for requests and jobs, logs, errors, and emails. Data is stored in Redis using RedisStack (Redis with TimeSeries module).

## Development Commands

### Start Redis (required for development/testing)
```bash
docker compose up -d redis-dev    # Development (port 6379)
docker compose up -d redis-test   # Testing (port 6399)
```

### Run the test dummy app
```bash
bin/rails server
```

### Run tests
```bash
bin/rails test                           # All tests
bin/rails test test/path/to/test.rb      # Single file
bin/rails test test/path/to/test.rb:42   # Single test at line
```

### Linting
```bash
bundle exec standardrb                   # Check style
bundle exec standardrb --fix             # Auto-fix
```

### Build frontend assets
```bash
npm run build   # One-time build
npm run watch   # Watch mode
```

## Architecture

### Core Data Flow
1. `RequestMiddleware` intercepts all requests at the top of the Rack stack
2. `EventCollector` captures all ActiveSupport::Notification events during request processing
3. `LogCollector` captures logs emitted during the request
4. Data is saved asynchronously via a worker pool to avoid blocking requests

### Key Abstractions

**RedisModel** (`lib/rails_observatory/redis_model.rb`): ActiveModel-like base class for models stored in Redis. Uses Redis JSON for storage and Redis Full Text Search (FT) for indexing. Supports attribute compression with zlib.

**RedisTimeSeries** (`lib/rails_observatory/redis_time_series.rb`): Wrapper around Redis TimeSeries module for metrics. Handles time-bucketed aggregations, queries, and range operations.

Query API:
- `RedisTimeSeries.query_range(name, reducer)` - Query time series data with multiple time bins (for charts)
- `RedisTimeSeries.query_value(name, reducer)` - Query a single aggregated value over the time range (for summary stats)
- `RedisTimeSeries.query_index(name)` - Query which time series exist
- `RedisTimeSeries.query_range_by_string(spec)` - Parse a spec string into a configured QueryRangeBuilder

**query_range_by_string format**: `"metric_name|compaction->bins@reducer (group_label)"`
- `metric_name` - The metric to query (e.g., `request.latency`)
- `compaction` - Which compaction to use (`sum`, `avg`, `min`, `max`) or `all` for any
- `bins` - Bucket duration in seconds (e.g., `60` for 1-minute bins)
- `reducer` - Aggregation function for bins (`sum`, `avg`, `min`, `max`)
- `(group_label)` - Optional: group results by this label instead of `name`

Examples:
- `"request.count|sum->60@sum"` - Count requests in 60-second bins
- `"request.latency|avg->60@avg (namespace)"` - Average latency grouped by namespace

**Use `query_value` for single metrics** (e.g., total request count, average latency). It aggregates the entire time range into one value. **Use `query_range` for charts** where you need multiple data points over time.

QueryRangeBuilder methods (chainable):
- `.where(**conditions)` - Filter by labels (use `true` for "exists", e.g., `action: true`)
- `.group(label)` - Group results by label
- `.bins(duration_ms)` - Set time bucket duration in milliseconds
- `.group_label` - Returns the current group label (default: `'name'`)

Terminal methods:
- `.sum` / `.avg` / `.last` - Aggregate and return hash indexed by group label
- `.to_a` - Return array of Range objects
- `.each` - Iterate over Range objects

Range objects have: `labels` (Hash with string keys), `data` (array of [timestamp, value]), `name`, `from`, `to`

QueryValueBuilder methods (chainable):
- `.where(**conditions)` - Filter by labels
- `.group(label)` - Group results by label

Value objects have: `labels` (Hash), `name`, `value` (Float)

**Time Range Handling**: Both `QueryRangeBuilder` and `QueryValueBuilder` fall back to `ActiveSupport::IsolatedExecutionState[:observatory_slice]` when no explicit `from:/to:` is provided. Controllers set this via `RedisTimeSeries.with_slice(time_range)` in an `around_action`.

Insertion API:
- `RedisTimeSeries.increment(name, at:, labels:)` - Increment a counter (alias: `record_occurrence`)
- `RedisTimeSeries.distribution(name, value, at:, labels:)` - Record a timing/value (alias: `record_timing`)

Both methods use the same pattern:
- Labels are hashed (SHA1) to create a unique series key per label-set
- Cold path: EXISTS check → SETNX lock → pipeline to create series + compactions
- Hot path: single `TS.ADD` call
- `increment` creates sum compaction; `distribution` creates avg/min/max compactions

**Important**: Redis TimeSeries auto-creates series on `TS.ADD`, so we use EXISTS check (not exception handling) to detect cold path.

### Models (in `lib/rails_observatory/models/`)
- `RequestTrace` - HTTP request traces (key prefix: `rt`)
- `JobTrace` - Background job traces
- `Error` - Captured exceptions
- `MailDelivery` - Captured emails (development only)

### Serializers (in `lib/rails_observatory/serializers/`)
Convert ActiveSupport::Notification events into storable format. Each event type (request, job, mail) has its own serializer.

### Engine Configuration
Configured in `lib/rails_observatory/engine.rb`. Redis connection defaults to localhost:6379. Override via `config.rails_observatory.redis` in the host application.

## Test Structure
- `test/dummy/` - Full Rails application for integration testing
- Tests use `redis-test` container on port 6399
- **Important**: Don't use `FLUSHALL` in tests - it removes indexes created by `test_helper.rb`. Instead, track test keys and delete them in teardown:
  ```ruby
  def setup
    @test_keys = []
    # create keys and track them: @test_keys << key
  end

  def teardown
    @test_keys.each { |key| @redis.call("DEL", key) }
  end
  ```

## Known Issues
- `RedisTimeSeries::Range` is missing a `value` method that `QueryRangeBuilder#sum` expects. Use `query_value` instead when you need a single aggregated value.
