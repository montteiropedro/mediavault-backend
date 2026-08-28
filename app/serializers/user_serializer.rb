class UserSerializer
  include Alba::Resource

  attribute :display_name do |user|
    user.display_name
  end
end
