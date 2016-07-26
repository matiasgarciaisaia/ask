require 'rails_helper'

RSpec.describe "Respondents", type: :request do
  describe "GET /respondents" do
    it "works! (now write some real specs)" do
      get respondents_path
      expect(response).to have_http_status(200)
    end
  end
end
