require 'rails_helper'

RSpec.describe "respondents/index", type: :view do
  before(:each) do
    assign(:respondents, [
      Respondent.create!(
        :phone_number => "Phone Number"
      ),
      Respondent.create!(
        :phone_number => "Phone Number"
      )
    ])
  end

  it "renders a list of respondents" do
    render
    assert_select "tr>td", :text => "Phone Number".to_s, :count => 2
  end
end
