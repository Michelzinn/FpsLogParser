FactoryBot.define do
  factory :kill do
    association :match
    association :killer, factory: :player
    association :victim, factory: :player
    weapon { "M16" }
    occurred_at { Time.current }
    world_kill { false }

    trait :world_kill do
      killer { nil }
      world_kill { true }
      weapon { "DROWN" }
    end
  end
end