module RailsObservatory
  class ResponseSerializer
    def serialize(response)
      {
        status: response.status,
        headers: Serializer.serialize(response.headers)
      }
    end

    def self.klass
      ActionDispatch::Response
    end
  end
end
