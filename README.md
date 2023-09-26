# Rails Observatory
<img src="https://raw.githubusercontent.com/mgodwin/rails_observatory/main/.github/logo_with_text.svg" height="80">

Simple metrics tracking for your Rails app.

Rails observatory hooks into ActiveSupport::Instrumentation with RedisTimeSeries to provide
a simple way to track metrics in your Rails app.

<img src="https://github.com/mgodwin/rails_observatory/blob/main/.github/observatory_screenshot.png?raw=true">

## Requirements

- Redis w/ [TimeSeries module](https://github.com/RedisTimeSeries/RedisTimeSeries) (or [RedisStack](https://github.com/redis-stack))
- Rails 6+

## Installation

```shell
bundle add observatory-rails
```

## Getting Started
Check out the Getting Started wiki page.


## Development

Run redis stack
https://redis.io/docs/getting-started/install-stack/docker/

```
docker run -d --name redis-stack -p 6379:6379 -p 8001:8001 redis/redis-stack:latest
```

## Notes

Q: I have many servers and use NTP, but possible the writes may be out-of-order, how will it be handled?

A: https://redis.io/docs/data-types/timeseries/reference/out-of-order_performance_considerations/
You will have a slight performance penalty depending on how out-of-order your data is. The penalty is proportional to the number of out-of-order samples.
Redis offers some great tips on how to optimize performance on their site.


Q: How much space does each metric take up?


You may configure the retention duration for your metrics.  Want to keep them for 20 years?  Up to you!
The only penalty is that the more data you keep, the more space it will take up.  The default is 1 year.

To store metrics, we use RedisTimeSeries and a few compaction rules to make querying speedy.
Raw Metrics are retained for 1 minute, then downsampled to per second 

> Uncompressed, the timestamp and the value each consume 8 bytes (or 16 bytes/128 bits in total) for each sample.

> So how much memory reduction can this technique give you? Not surprisingly, the actual reduction depends on your use case, but we noticed a 94% reduction in our benchmark datasets. According to page six of Facebook’s Gorilla paper, each sample consumes an average of 1.37 bytes, compared to 16 bytes. This results in a 90% memory reduction for the most common use cases.

So after crunching the numbers, with default settings, you can 

https://redis.com/blog/redistimeseries-version-1-2-is-here/

Q: Attaching labels to metrics

You can attach labels/tags to metrics to make them easier to query, however
each tag/label creates a new time series, so be careful not to create too many.

The combination of the tags and labels will be the number of time series created,
so if you're creating dynamic tags, you need to be careful to use **low cardinality**
tag values or you could end up eating all your space.

Q: Configuring Retention Periods

By default there is a geared retention period based on the resolution of the metric.
This means that the raw data is kept for 1 minute, then downsampled to per second
for 1 hour, then downsampled to per minute for 1 day, then downsampled to per hour
for 1 week, then downsampled to per day for 1 month, then downsampled to per week
for 1 year.

You can configure this to your liking, but be aware that you will be using more space
if you keep more data.

For estimation purposes, you can use the following formula:

16bytes per event * number of events expected = size in bytes

You should be able to go from there to figure out how much space you need.


## Labels

Labels are a way to attach metadata to your metrics.  They are stored as a hash
in redis.

https://redis.io/commands/ts.queryindex/

filterExpr...
filters time series based on their labels and label values. Each filter expression has one of the following syntaxes:
label=value, where label equals value
label!=value, where label does not equal value
label=, where key does not have label label
label!=, where key has label label
label=(value1,value2,...), where key with label label equals one of the values in the list
label!=(value1,value2,...), where key with label label does not equal any of the values in the list


They're a way to find corresponding time series without having to iterate across all keys
in redis.

You _cannot_ have two time series with the same name and different labels.  You need to include
differentiating labels in the **key** of the time series.





## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
