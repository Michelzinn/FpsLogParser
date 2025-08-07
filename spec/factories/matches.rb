FactoryBot.define do
  factory :match do
    sequence(:match_id) { |n| "1134896#{n}" }
    started_at { 1.hour.ago }
    ended_at { Time.current }
  end
end