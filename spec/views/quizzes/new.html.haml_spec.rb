require 'rails_helper'

RSpec.describe "quizzes/new", type: :view do
  before(:each) do
    assign(:quiz, Quiz.new(
      :name => "MyString",
      :description => "MyText",
      :channels => nil,
      :survey => nil,
      :question => nil
    ))
  end

  it "renders new quiz form" do
    render

    assert_select "form[action=?][method=?]", quizzes_path, "post" do

      assert_select "input#quiz_name[name=?]", "quiz[name]"

      assert_select "textarea#quiz_description[name=?]", "quiz[description]"

      assert_select "input#quiz_channel_id[name=?]", "quiz[channel_id]"

      assert_select "input#quiz_survey_id[name=?]", "quiz[survey_id]"

      assert_select "input#quiz_question_id[name=?]", "quiz[question_id]"
    end
  end
end
