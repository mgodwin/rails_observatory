module RailsObservatory
  module ApplicationHelper

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
