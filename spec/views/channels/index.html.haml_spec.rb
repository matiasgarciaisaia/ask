require 'rails_helper'

RSpec.describe "channels/index", type: :view do
  before(:each) do
    assign(:channels, [
      Channel.create!(
        :name => "Name",
        :quiz => nil
      ),
      Channel.create!(
        :name => "Name",
        :quiz => nil
      )
    ])
  end

  it "renders a list of channels" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
