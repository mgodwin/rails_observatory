module RailsObservatory
  class RequestSerializer
    def serialize(request)
      {
        method: request.method,
        path: request.path,
        format: request.format,
        route_pattern: request.route_uri_pattern,
        headers: Serializer.serialize(request.headers),
      }
    end

    def self.klass
      ActionDispatch::Request
    end
  end
end