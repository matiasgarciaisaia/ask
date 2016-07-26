require 'rails_helper'

RSpec.describe "respondents/new", type: :view do
  before(:each) do
    assign(:respondent, Respondent.new(
      :phone_number => "MyString"
    ))
  end

  it "renders new respondent form" do
    render

    assert_select "form[action=?][method=?]", respondents_path, "post" do

      assert_select "input#respondent_phone_number[name=?]", "respondent[phone_number]"
    end
  end
end
