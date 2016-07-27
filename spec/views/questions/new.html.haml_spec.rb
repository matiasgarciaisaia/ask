require 'rails_helper'

RSpec.describe "questions/new", type: :view do
  before(:each) do
    assign(:question, create(:question))
  end

  it "renders new question form" do
    render

    assert_select "form[action=?][method=?]", questions_path, "post" do

      assert_select "input#question_name[name=?]", "question[name]"

      assert_select "textarea#question_text[name=?]", "question[text]"

      assert_select "input#question_quiz_id[name=?]", "question[quiz_id]"
    end
  end
end
