require 'rails_helper'

RSpec.describe "quizzes/edit", type: :view do
  before(:each) do
    @quiz = assign(:quiz, create(:quiz))
  end

  it "renders the edit quiz form" do
    render

    assert_select "form[action=?][method=?]", quiz_path(@quiz), "post" do

      assert_select "input#quiz_name[name=?]", "quiz[name]"

      assert_select "textarea#quiz_description[name=?]", "quiz[description]"

      assert_select "input#quiz_channel_id[name=?]", "quiz[channel_id]"

      assert_select "input#quiz_survey_id[name=?]", "quiz[survey_id]"

      assert_select "input#quiz_question_id[name=?]", "quiz[question_id]"
    end
  end
end
