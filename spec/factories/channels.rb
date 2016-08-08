FactoryGirl.define do
  factory :channel do
    user
    name "MyString"
    add_attribute :method, "voice"
    settings verboice_channel_name: 'foo', verboice_project_id: '42', verboice_url: "http://example.com", verboice_user: "John Doe", verboice_password: "S0m3 P4ssw0rd?"
  end
end
