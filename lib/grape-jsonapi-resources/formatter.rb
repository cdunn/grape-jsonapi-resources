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
          sorted_primary_ids = nil
          if resource.respond_to?(:to_ary)
            resource_instances = resource.to_ary.compact.collect do |each_resource|
              each_resource_class = resource_class_for(each_resource)
              each_resource_class.new(each_resource, context)
            end
            sorted_primary_ids = resource_instances.collect { |resource_instance| resource_instance.try(:id) }
          else
            resource_instances = resource_class.new(resource, context)
          end

          resource_serialzed = JSONAPI::ResourceSerializer.new(resource_class, jsonapi_options).serialize_to_hash(resource_instances)
          json_output = if jsonapi_options[:meta]
            # Add option to merge top level meta tag as jsonapi-resources does not appear to support this
            resource_serialzed.as_json.merge(meta: jsonapi_options[:meta])
          else
            resource_serialzed
          end

          # Ensure sort order is maintained, serialize_to_hash can reorder objects if
          # objects of the array are of different types (polymorphic cases)
          json_output = json_output.stringify_keys
          if sorted_primary_ids && (data = json_output["data"]).present?
            sorted_primary_ids = sorted_primary_ids.map(&:to_s)
            json_output["data"] = data.sort_by { |d| sorted_primary_ids.index(d["id"]) }
          end

          json_output.to_json
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
