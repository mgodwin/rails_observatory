# Rails Observatory

Observability for your Rails app.

Rails observatory hooks into ActiveSupport::Instrumentation
with [RedisStack](https://redis.io/docs/about/about-stack/) to provide
a simple way to observe what is happening your Rails app, without third party integrations.

<img src="https://github.com/mgodwin/rails_observatory/blob/main/.github/observatory_trace.png?raw=true">

## Features

- A simple APM to see what is happening in your application
- Traces for requests and jobs, and an interface to view them
- Captures logs emitted during a trace and provides an interface to view them
- Captures errors and provides an interface to view them
- In development, captures all delivered emails and provides an interface to view them

## Requirements

- Redis w/ [TimeSeries module](https://github.com/RedisTimeSeries/RedisTimeSeries) (
  or [RedisStack](https://github.com/redis-stack))
- Rails 7+

## Installation

```shell
bundle add observatory-rails
```

## Getting Started

Check out the Getting Started wiki page.

## Contributing

Pull requests, issues and more are welcome!

## License

The gem is available as open source under the terms of the MIT License.
