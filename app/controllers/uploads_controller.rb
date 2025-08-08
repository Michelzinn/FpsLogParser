class UploadsController < ApplicationController
  def index
  end

  def create
    result = LogParser.new(params[:log_file].read).parse

    if result.success?
      @processed = result.value![:processed]
      @errors = result.value![:errors] || []
    else
      @processed = 0
      @errors = [ error_message(result.failure) ]
    end
  end

  private

  def error_message(failure_type)
    error_message_mapping ={
      empty_content: "The uploaded file is empty",
      no_valid_lines: "No valid log lines found"
    }
    error_message_mapping[failure_type] || "Unexpected error"
  end
end
