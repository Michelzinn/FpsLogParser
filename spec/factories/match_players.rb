FactoryBot.define do
  factory :match_player do
    association :match
    association :player
    kills_count { 0 }
    deaths_count { 0 }
  end
end