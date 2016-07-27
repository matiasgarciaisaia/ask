require 'rails_helper'

RSpec.describe "channels/new", type: :view do
  before(:each) do
    assign(:channel, Channel.new(
      :name => "MyString",
      :quiz => nil
    ))
  end

  it "renders new channel form" do
    render

    assert_select "form[action=?][method=?]", channels_path, "post" do

      assert_select "input#channel_name[name=?]", "channel[name]"

      assert_select "input#channel_quiz_id[name=?]", "channel[quiz_id]"
    end
  end
end
