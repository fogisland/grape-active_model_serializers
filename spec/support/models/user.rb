class User < ActiveModelSerializers::Model
  attr_accessor :first_name, :last_name, :password, :email
end
