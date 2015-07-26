module Grape
  module Formatter
    module JSONAPIResources
      class << self
        def call(resource, env)
          serialized_resource = serialize_resource(resource, env)
          serialized_resource ? serialized_resource : Grape::Formatter::Json.call(resource, env)
        end

        def serialize_resource(resource, env)
          endpoint = env['api.endpoint']

          jsonapi_options = build_options_from_endpoint(endpoint)
          jsonapi_options.merge!(env['jsonapi_options'] || {})

          context = {}
          context.merge!(current_user: endpoint.current_user) if endpoint.respond_to?(:current_user)
          context.merge!(jsonapi_options.delete(:context)) if jsonapi_options[:context]

          resource_class = resource_class_for(resource)
          return nil unless resource_class
          resource_instances = nil
          if resource.respond_to?(:to_ary)
            resource_instances = resource.to_ary.collect do |each_resource|
              resource_class.new(each_resource, context)
            end
          else
            resource_instances = resource_class.new(resource, context)
          end

          JSONAPI::ResourceSerializer.new(resource_class, jsonapi_options).serialize_to_hash(resource_instances)
        end

        def build_options_from_endpoint(endpoint)
          options = {}
          options[:base_url] = endpoint.namespace_inheritable(:jsonapi_base_url) if endpoint.namespace_inheritable(:jsonapi_base_url)
          options
        end

        def resource_class_for(resource)
          if resource.class.respond_to?(:jsonapi_resource_class)
            resource.class.jsonapi_resource_class
          elsif resource.respond_to?(:to_ary)
            resource_class_for(resource.to_ary.first)
          else
            get_resource_for(resource.class)
          end
        end

        def resources_cache
          @resources_cache ||= ThreadSafe::Cache.new
        end

        def get_resource_for(klass)
          resources_cache.fetch_or_store(klass) do
            resource_class_name = "#{klass.name}Resource"
            resource_class = resource_class_name.safe_constantize

            if resource_class
              resource_class
            elsif klass.superclass
              get_resource_for(klass.superclass)
            end
          end
        end
      end
    end
  end
end
