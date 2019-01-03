require 'test_helper'

class UnitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @unit = units(:one)
  end

  test "should get index" do
    get units_url
    assert_response :success
  end

  test "should get new" do
    get new_unit_url
    assert_response :success
  end

  test "should create unit" do
    assert_difference('Unit.count') do
      post units_url, params: { unit: { armor_type: @unit.armor_type, attack_type: @unit.attack_type, can_attack: @unit.can_attack, immune_to_magic: @unit.immune_to_magic, name: @unit.name, notes: @unit.notes, race: @unit.race, tier: @unit.tier } }
    end

    assert_redirected_to unit_url(Unit.last)
  end

  test "should show unit" do
    get unit_url(@unit)
    assert_response :success
  end

  test "should get edit" do
    get edit_unit_url(@unit)
    assert_response :success
  end

  test "should update unit" do
    patch unit_url(@unit), params: { unit: { armor_type: @unit.armor_type, attack_type: @unit.attack_type, can_attack: @unit.can_attack, immune_to_magic: @unit.immune_to_magic, name: @unit.name, notes: @unit.notes, race: @unit.race, tier: @unit.tier } }
    assert_redirected_to unit_url(@unit)
  end

  test "should destroy unit" do
    assert_difference('Unit.count', -1) do
      delete unit_url(@unit)
    end

    assert_redirected_to units_url
  end
end
