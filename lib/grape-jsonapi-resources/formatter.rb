module Grape
  module Formatter
    module JSONAPIResources
      class << self
        def call(resource, env)
          serialize_resource(resource, env) || Grape::Formatter::Json.call(resource, env)
        end

        def serialize_resource(resource, env)
          endpoint = env['api.endpoint']

          jsonapi_options = build_options_from_endpoint(endpoint)
          jsonapi_options.merge!(env['jsonapi_options'] || {})

          context = {}
          context.merge!(current_user: endpoint.current_user) if endpoint.respond_to?(:current_user)
          context.merge!(jsonapi_options.delete(:context)) if jsonapi_options[:context]

          resource_class = resource_class_for(resource)

          if resource_class.nil?
            if resource.blank?
              # Return blank object
              blank_return = {}
              if resource.respond_to?(:to_ary)
                blank_return[:data] = []
              else
                blank_return[:data] = {}
              end
              blank_return[:meta] = jsonapi_options[:meta] if jsonapi_options[:meta]
              return blank_return.to_json
            else
              return nil
            end
          end

          resource_instances = nil
          if resource.respond_to?(:to_ary)
            resource_instances = resource.to_ary.collect do |each_resource|
              resource_class.new(each_resource, context)
            end
          else
            resource_instances = resource_class.new(resource, context)
          end

          resource_serialzer = JSONAPI::ResourceSerializer.new(resource_class, jsonapi_options).serialize_to_hash(resource_instances)
          if jsonapi_options[:meta]
            # Add option to merge top level meta tag as jsonapi-resources does not appear to support this
            resource_serialzer.as_json.merge(meta: jsonapi_options[:meta]).to_json if jsonapi_options[:meta]
          else
            resource_serialzer.to_json
          end
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
