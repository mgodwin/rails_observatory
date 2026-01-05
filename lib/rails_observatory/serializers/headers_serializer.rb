module RailsObservatory
  class HeadersSerializer
    def serialize(headers)
      http_headers = Hash[*headers.select { |k, v| k.start_with?("HTTP_") }.flatten]
      http_headers.transform_keys! { |k| k.sub("HTTP_", "").downcase.capitalize.dasherize }
    end

    def self.klass
      ActionDispatch::Http::Headers
    end
  end
end
