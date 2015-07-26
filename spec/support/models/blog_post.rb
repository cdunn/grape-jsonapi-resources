class BlogPost
  include ActiveModel::Model
  include ActiveModel::Serialization

  attr_accessor :id, :title, :body

  def initialize(params = {})
    @id = 1
    params.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end
end
