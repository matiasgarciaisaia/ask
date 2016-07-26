require 'rails_helper'

RSpec.describe "respondents/edit", type: :view do
  before(:each) do
    @respondent = assign(:respondent, Respondent.create!(
      :phone_number => "MyString"
    ))
  end

  it "renders the edit respondent form" do
    render

    assert_select "form[action=?][method=?]", respondent_path(@respondent), "post" do

      assert_select "input#respondent_phone_number[name=?]", "respondent[phone_number]"
    end
  end
end
