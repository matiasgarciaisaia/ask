require 'faker'

FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password { Faker::Name.name }
    password_confirmation { password }
    confirmed_at { Time.now - 1.day }
  end
end
