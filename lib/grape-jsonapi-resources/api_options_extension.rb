module Grape
  class API
    class << self
      def jsonapi_base_url(url = nil)
        namespace_inheritable(:jsonapi_base_url, url)
      end
    end
  end
end
