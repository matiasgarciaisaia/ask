FactoryGirl.define do
  factory :channel do
    name "MyString"
    quiz
    url "example.com"
    user "John Doe"
    password "S0m3 P4ssw0rd?"
    add_attribute :method, "voice"
  end
end
