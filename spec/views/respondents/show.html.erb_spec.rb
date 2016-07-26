require 'rails_helper'

RSpec.describe "respondents/show", type: :view do
  before(:each) do
    @respondent = assign(:respondent, Respondent.create!(
      :phone_number => "Phone Number"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Phone Number/)
  end
end
