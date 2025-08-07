FactoryBot.define do
  factory :player do
    sequence(:name) { |n| "Player#{n}" }
  end
end