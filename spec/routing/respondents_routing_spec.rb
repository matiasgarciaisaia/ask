require "rails_helper"

RSpec.describe RespondentsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/respondents").to route_to("respondents#index")
    end

    it "routes to #new" do
      expect(:get => "/respondents/new").to route_to("respondents#new")
    end

    it "routes to #show" do
      expect(:get => "/respondents/1").to route_to("respondents#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/respondents/1/edit").to route_to("respondents#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/respondents").to route_to("respondents#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/respondents/1").to route_to("respondents#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/respondents/1").to route_to("respondents#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/respondents/1").to route_to("respondents#destroy", :id => "1")
    end

  end
end
