FactoryGirl.define do
  factory :respondent do
    sequence(:phone_number, 11234567890)
    survey
  end
end
