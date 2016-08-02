FactoryGirl.define do
  factory :answer do
    text "MyText"
    respondent
    question
  end
end
