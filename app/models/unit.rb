class Unit < ApplicationRecord
  ARMOR_TYPES = ["Light", "Medium", "Heavy", "Fortified", "Hero", "Unarmored"].freeze
  ARMY_COMPOSITION_TYPES = ["Damage Dealt", "Damage Taken", "Total Power"].freeze
  ATTACK_TYPES = ["Normal", "Piercing", "Siege", "Chaos", "Magic", "Hero"].freeze
  CAN_ATTACK_OPTIONS = ["Ground", "Air", "Ground + Air"]
  RACES = ["Human", "Night Elf", "Orc", "Undead"].freeze
  TIERS = [1,2,3].freeze

  validates :armor_type, :attack_type, :name, :race, :tier, :can_attack, presence: true
  validates :armor_type, inclusion: { in: ARMOR_TYPES, message: "must be one of: #{ARMOR_TYPES.join(", ")}" }
  validates :attack_type, inclusion: { in: ATTACK_TYPES, message: "must be one of: #{ATTACK_TYPES.join(", ")}" }
  validates :can_attack, inclusion: { in: CAN_ATTACK_OPTIONS, message: "must be one of: #{CAN_ATTACK_OPTIONS.join(", ")}" }
  validates :immune_to_magic, inclusion: { in: [true, false], message: "must be true or false" }
  validates :race, inclusion: { in: RACES, message: "must be one of: #{RACES.join(", ")}" }
  validates :tier, inclusion: { in: TIERS, message: "must be one of: #{TIERS.join(", ")}" }

  def self.unit_counters(units, race, tier, army_composition_type)
    units.map do |unit|
      best_counter_units = unit.best_counter_units(race, tier, army_composition_type)
      { unit: unit, counters: best_counter_units }
    end
  end

  def self.counters_display_hash(counters, army_composition_type)
    hash = {}
    counters.each do |counter|
      unit = counter[:unit]
      counter_unit = counter[:counters].first
      hash[counter_unit.name] ||= []
      hash[counter_unit.name] << [counter_unit.power_info(unit, army_composition_type), unit.name]
    end

    hash
  end

  def power_info(unit, army_composition_type)
    case army_composition_type
    when "Total Power"
      power = sprintf("%+d", power_against(unit))
      "#{power} PWR"
    when "Damage Dealt"
      power = deals_damage_against(unit)
      "deals #{power}%"
    when "Damage Taken"
      power = takes_damage_from(unit)
      "takes #{power}%"
    end
  end

  def self.power_verb(army_composition_type)
    case army_composition_type
    when "Total Power"
      "vs."
    when "Damage Dealt"
      "to"
    when "Damage Taken"
      "from"
    end
  end

  def deals_damage_against(unit)
    damage_dealt = if unit.immune_to_magic && attack_type == "Magic"
      0
    else
      Unit.armor_to_attack[unit.armor_type.downcase][attack_type.downcase]
    end

    if unit.name == "Footman (with Defend)" && attack_type == "Piercing"
      (damage_dealt / 2.0).to_i
    else
      damage_dealt
    end
  end

  def takes_damage_from(unit)
    damage_taken = if immune_to_magic && unit.attack_type == "Magic"
      0
    else
      Unit.armor_to_attack[armor_type.downcase][unit.attack_type.downcase]
    end

    if name == "Footman (with Defend)" && unit.attack_type == "Piercing"
      damage_taken / 2.0
    else
      damage_taken
    end
  end

  def power_against(unit)
    deals_damage_against(unit) - takes_damage_from(unit)
  end

  def attack_power_comparison(unit_a, unit_b)
    a_attack_power = unit_a.deals_damage_against(self)
    b_attack_power = unit_b.deals_damage_against(self)

    if a_attack_power == b_attack_power
      if unit_a.tier == unit_b.tier
        total_power_comparison(unit_a, unit_b)
      else
        unit_a.tier > unit_b.tier ? -1 : 1
      end
    else
      a_attack_power > b_attack_power ? -1 : 1
    end
  end

  def defense_comparison(unit_a, unit_b)
    a_damage_taken = unit_a.takes_damage_from(self)
    b_damage_taken = unit_b.takes_damage_from(self)

    if a_damage_taken == b_damage_taken
      if unit_a.tier == unit_b.tier
        total_power_comparison(unit_a, unit_b)
      else
        unit_a.tier > unit_b.tier ? -1 : 1
      end
    else
      a_damage_taken < b_damage_taken ? -1 : 1
    end
  end

  def total_power_comparison(unit_a, unit_b)
    a_power = unit_a.power_against(self)
    b_power = unit_b.power_against(self)

    if a_power == b_power
      if unit_a.tier == unit_b.tier
        if unit_a.immune_to_magic == unit_b.immune_to_magic
          0
        else
          unit_a.immune_to_magic? ? -1 : 1
        end
      else
        unit_a.tier > unit_b.tier ? -1 : 1
      end
    else
      a_power > b_power ? -1 : 1
    end
  end

  def best_counter_units(race, tier, army_composition_type)
    20.times { puts "calculating counter units..." }
    units = Unit.where(race: race).where("tier <= ?", tier).sort do |unit_a, unit_b|
      case army_composition_type
      when "Total Power"
        total_power_comparison(unit_a, unit_b)
      when "Damage Dealt"
        attack_power_comparison(unit_a, unit_b)
      when "Damage Taken"
        defense_comparison(unit_a, unit_b)
      end
    end.first(3)

    20.times { puts "done calculating counter units: #{units.map { |u| [u.name, u.power_against(self)] }}" }
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
