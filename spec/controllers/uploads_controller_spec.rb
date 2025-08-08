require 'rails_helper'

RSpec.describe UploadsController, type: :controller do
  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    let(:file_content) do
      <<~LOG
        23/04/2019 15:34:22 - New match 11348965 has started
        23/04/2019 15:36:04 - Roman killed Nick using M16
        23/04/2019 15:39:22 - Match 11348965 has ended
      LOG
    end

    let(:file) do
      Rack::Test::UploadedFile.new(StringIO.new(file_content), "text/plain", original_filename: "test.log")
    end

    it "processes the uploaded file" do
      post :create, params: { log_file: file }, format: :turbo_stream

      expect(assigns(:processed)).to eq(3)
      expect(assigns(:errors)).to be_empty
      expect(response).to render_template(:create)
    end

    context "with empty file" do
      let(:file_content) { "" }

      it "handles empty content" do
        post :create, params: { log_file: file }, format: :turbo_stream

        expect(assigns(:processed)).to eq(0)
        expect(assigns(:errors)).to include("The uploaded file is empty")
      end
    end
  end
end
