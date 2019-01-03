class Unit < ApplicationRecord
  ARMOR_TYPES = ["Light", "Medium", "Heavy", "Fortified", "Hero", "Unarmored"].freeze
  ATTACK_TYPES = ["Normal", "Piercing", "Siege", "Chaos", "Magic", "Hero"].freeze
  CAN_ATTACK_OPTIONS = ["Ground", "Air", "Ground + Air"]
  RACES = ["Human", "Undead", "Night Elf", "Orc"].freeze
  TIERS = [1,2,3].freeze

  validates :armor_type, :attack_type, :name, :race, :tier, :can_attack, presence: true
  validates :armor_type, inclusion: { in: ARMOR_TYPES, message: "must be one of: #{ARMOR_TYPES.join(", ")}" }
  validates :attack_type, inclusion: { in: ATTACK_TYPES, message: "must be one of: #{ATTACK_TYPES.join(", ")}" }
  validates :can_attack, inclusion: { in: CAN_ATTACK_OPTIONS, message: "must be one of: #{CAN_ATTACK_OPTIONS.join(", ")}" }
  validates :immune_to_magic, inclusion: { in: [true, false], message: "must be true or false" }
  validates :race, inclusion: { in: RACES, message: "must be one of: #{RACES.join(", ")}" }
  validates :tier, inclusion: { in: TIERS, message: "must be one of: #{TIERS.join(", ")}" }

  def self.unit_counters(units, race, tier)
    units.map do |unit|
      best_counter_units = unit.best_counter_units(race, tier)
      { unit: unit, counters: unit.best_counter_units(race, tier) }
    end
  end

  def deals_damage_against(unit)
    Unit.armor_to_attack[unit.armor_type.downcase][attack_type.downcase]
  end

  def best_counter_units(race, tier)
    units = {
      best: Unit.none,
      good: Unit.none
    }
    armor_index = 0
    attack_index = 0

    while units[:good].count == 0 && attack_index < 6
      puts "best counter attack type for #{name} is #{best_counter_attack_type(attack_index)}"
      while units[:good].count == 0 && armor_index < 6
        puts "best counter armor type for #{name} (#{armor_index}) is #{best_counter_armor_type(armor_index)}"
        if immune_to_magic && best_counter_attack_type(attack_index) == "Magic"
          counter_units = Unit.none
        else
          counter_units = Unit.where(
            race: race,
            attack_type: best_counter_attack_type(attack_index),
            armor_type: best_counter_armor_type(armor_index)
          ).where(
            "tier <= ?", tier
          ).order(tier: :desc)
        end
        units[:best].count == 0 ? units[:best] = counter_units : units[:good] = counter_units
        armor_index += 1
      end
      attack_index += 1
      armor_index = 0
    end

    units
  end

  def best_counter_attack_type(i)
    attack_types = Unit.armor_to_attack[armor_type.downcase]
    attack_types.sort_by { |attack_type, percent| percent }.reverse[i].first.capitalize
  end

  def best_counter_armor_type(i)
    armor_types = Unit.attack_to_armor[attack_type.downcase]
    armor_types.sort_by { |armor_type, percent| percent }[i].first.capitalize
  end

  def self.armor_to_attack
    {
      light: { normal: 100, piercing: 200, siege: 100, magic: 125, chaos: 100, hero: 100 },
      medium: { normal: 150, piercing: 75, siege: 50, magic: 75, chaos: 100, hero: 100 },
      heavy: { normal: 100, piercing: 100, siege: 100, magic: 200, chaos: 100, hero: 100 },
      fortified: { normal: 70, piercing: 35, siege: 150, magic: 35, chaos: 100, hero: 50 },
      hero: { normal: 100, piercing: 50, siege: 50, magic: 50, chaos: 100, hero: 100 },
      unarmored: { normal: 100, piercing: 150, siege: 150, magic: 100, chaos: 100, hero: 100 }
    }.with_indifferent_access
  end

  def self.attack_to_armor
    attack_to_armor = {}
    armor_to_attack.each do |armor_type, attack_types|
      attack_types.each do |attack_type, percent|
        attack_to_armor[attack_type] ||= {}
        attack_to_armor[attack_type][armor_type] = percent
      end
    end
    attack_to_armor.with_indifferent_access
  end
end
