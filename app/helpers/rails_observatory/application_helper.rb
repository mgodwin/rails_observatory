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

  def add_breadcrumb(name, path)
    @breadcrumbs ||= []
    @breadcrumbs << [name, path]
  end

  def breadcrumbs
    @breadcrumbs ||= []
    @breadcrumbs
  end

  def has_breadcrumbs?
    @breadcrumbs ||= []
    @breadcrumbs.any?
  end
end
end
