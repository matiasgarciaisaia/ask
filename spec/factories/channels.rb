FactoryGirl.define do
  factory :channel do
    name "MyString"
    quiz
    url "example.com"
    user "John Doe"
    password "S0m3 P4ssw0rd?"
    add_attribute :method, "voice"
    settings verboice_channel_name: 'foo', verboice_project_id: '42'
  end
end
