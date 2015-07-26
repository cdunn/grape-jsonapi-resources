# Grape::JSONAPIResources

Use [jsonapi-resources](https://github.com/cerebris/jsonapi-resources) with [Grape](https://github.com/intridea/grape)!

## Installation

Add the `grape` and `grape-jsonapi-resources` gems to Gemfile.

```ruby
gem 'grape'
gem 'grape-jsonapi-resources'
```

## Usage

### Require grape-jsonapi-resources

### Tell your API to use Grape::Formatter::JSONAPIResources

```ruby
class API < Grape::API
  format :json
  formatter :json, Grape::Formatter::JSONAPIResources
end
```

### Use `render` to specify JSONAPI options

```ruby
get "/" do
  user = User.find("123")
  render user, include: ["account"], context: { something: :important }
end
```

## Credit

Code adapted from [grape-active_model_serializers](https://github.com/jrhe/grape-active_model_serializers)
