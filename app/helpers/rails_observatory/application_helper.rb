require 'rouge'
module RailsObservatory
  module ApplicationHelper

    def highlight_source_extract(source_extract)
      source_extract.symbolize_keys => { code:, line_number: }
      fmt = Rouge::Formatters::HTMLLineTable.new(Rouge::Formatters::HTML.new, start_line: code.keys.first.to_s.to_i)
      html = Nokogiri::HTML4(Rouge.highlight(code.values.flatten.join(""), 'ruby', fmt))
      html.css("#line-#{line_number}").add_class('hll')
      line = code[line_number.to_s]
      if line.length > 1
        html.css("#line-#{line_number}").attr('data-highlight-start', line[0].length).attr('data-highlight-length', line[1].length)
      end
      html.to_html
    end

    # Converts a query spec string into chart-ready series data.
    # See RedisTimeSeries.query_range_by_string for format details.
    def metric_series(spec)
      slice = ActiveSupport::IsolatedExecutionState[:observatory_slice]
      query = RedisTimeSeries.query_range_by_string(spec, from: slice&.begin, to: slice&.end)
      group_label = query.group_label.to_s
      query.to_a.map { |s| { name: s.labels[group_label], data: s.filled_data } }
    end

    def metric_value(name:, **labels)
      compaction_name = name.split('_').last
      metric_name = name.gsub(/_(sum|avg|min|max)$/, '')
      result = RedisTimeSeries.query_value(metric_name, compaction_name.to_sym)
                              .where(**labels)
                              .to_a
                              .first
      result&.value&.round(2)
    end

    def time_slice_start
      @time_range.begin.to_i * 1000
    end

    def time_slice_end
      time = @time_range.end.nil? ? Time.now.to_i : @time_range.end.to_i
      time * 1000
    end

    def format_event_value(value)
      if value.is_a?(Numeric)
        value.round(2)
      else
        value
      end
    end

    def duration_label(duration)
      unit, value = duration.parts.sort_by { |unit,  _ | ActiveSupport::Duration::PARTS.index(unit) }.first
      "#{value.round}#{unit[0]}"
    end

    def pretty_backtrace_location(backtrace_line)
      path, lineno, method = backtrace_line.split(':')
      path = path.sub(Gem.paths.home, '')
      # remove 'in ' from method name
      method = method.match(/in `([^']+) (:?in .*)'/)
      method = method[1] if method
      tag.div(class: 'backtrace-line') do
        tag.span(path, class: '_path') +
          ' in ' +
          tag.span(method, class: '_method') +
          ' at line ' +
          tag.span(lineno, class: '_lineno')

      end
    end

    def preview_mail_path(message_id)
      "/rails/mailers/delivered_mail/preview?message_id=#{message_id}"
    end

    def flatten_params(params, prefix = nil)
      params.each_with_object({}) do |(key, value), result|
        full_key = prefix ? "#{prefix}.#{key}" : key.to_s
        if value.is_a?(Hash)
          result.merge!(flatten_params(value, full_key))
        else
          result[full_key] = value
        end
      end
    end

    # {"used_memory"=>"46573752",
    #  "used_memory_human"=>"44.42M",
    #  "used_memory_rss"=>"70778880",
    #  "used_memory_rss_human"=>"67.50M",
    #  "used_memory_peak"=>"49028032",
    #  "used_memory_peak_human"=>"46.76M",
    #  "used_memory_peak_perc"=>"94.99%",
    #  "used_memory_overhead"=>"2195208",
    #  "used_memory_startup"=>"1118008",
    #  "used_memory_dataset"=>"44378544",
    #  "used_memory_dataset_perc"=>"97.63%",
    #  "allocator_allocated"=>"46540912",
    #  "allocator_active"=>"70693888",
    #  "allocator_resident"=>"70693888",
    #  "total_system_memory"=>"8225423360",
    #  "total_system_memory_human"=>"7.66G",
    #  "used_memory_lua"=>"84992",
    #  "used_memory_lua_human"=>"83.00K",
    #  "used_memory_scripts"=>"4768",
    #  "used_memory_scripts_human"=>"4.66K",
    #  "number_of_cached_scripts"=>"2",
    #  "maxmemory"=>"0",
    #  "maxmemory_human"=>"0B",
    #  "maxmemory_policy"=>"noeviction",
    #  "allocator_frag_ratio"=>"1.52",
    #  "allocator_frag_bytes"=>"24152976",
    #  "allocator_rss_ratio"=>"1.00",
    #  "allocator_rss_bytes"=>"0",
    #  "rss_overhead_ratio"=>"1.00",
    #  "rss_overhead_bytes"=>"84992",
    #  "mem_fragmentation_ratio"=>"1.52",
    #  "mem_fragmentation_bytes"=>"24237968",
    #  "mem_not_counted_for_evict"=>"0",
    #  "mem_replication_backlog"=>"0",
    #  "mem_clients_slaves"=>"0",
    #  "mem_clients_normal"=>"51176",
    #  "mem_aof_buffer"=>"0",
    #  "mem_allocator"=>"libc",
    #  "active_defrag_running"=>"0",
    #  "lazyfree_pending_objects"=>"0",
    #  "lazyfreed_objects"=>"0"}
    def redis_mem_info
      @info ||= Rails.configuration.rails_observatory.redis.call('info', 'memory').split("\r\n").slice(1..).map { _1.split(":") }.to_h
    end

    def max_memory_display
      info = redis_mem_info
      maxmemory = info['maxmemory'].to_i

      if maxmemory > 0
        info['maxmemory_human']
      elsif rails_max_memory = rails_observatory_max_memory
        number_to_human_size(rails_max_memory)
      else
        info['used_memory_rss_human']
      end
    end

    private

    def rails_observatory_max_memory
      config = Rails.configuration.rails_observatory
      config_max = config.respond_to?(:max_memory) ? config.max_memory : nil
      return config_max if config_max

      ENV['RAILS_OBSERVATORY_MAX_MEMORY']&.to_i&.then { |v| v > 0 ? v : nil }
    end
  end
end
