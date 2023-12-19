module RailsObservatory
  module ApplicationHelper

    def buckets_for_chart(time_range)

      end_time = time_range.end.nil? ? Time.now : time_range.end
      start_time = time_range.begin
      duration = end_time - start_time
      # 10 second buckets are the smallest resolution we have
      buckets_in_time_frame = (duration / 10.0).to_i
      [120, buckets_in_time_frame].min
    end

    def format_event_value(value)
      if value.is_a?(Numeric)
        value.round(2)
      else
        value
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
  end
end
