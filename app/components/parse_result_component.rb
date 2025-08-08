# frozen_string_literal: true

class ParseResultComponent < ViewComponent::Base
  def initialize(processed:, errors: [])
    @processed = processed
    @errors = errors
  end

  private

  attr_reader :processed, :errors

  def has_errors?
    errors.present?
  end
end
