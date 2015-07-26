class User
  include ActiveModel::Model
  include ActiveModel::Serialization

  attr_accessor :id, :first_name, :last_name, :password, :email

  def initialize(params = {})
    @id = 1
    params.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end
end
