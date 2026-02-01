# frozen_string_literal: true
#
# A gardener tends the garden.
# They have soil, and they know how to plant.

require_relative 'seed'

class Gardener
  attr_reader :name, :soil

  def initialize(name, soil: nil)
    @name = name
    @soil = soil || Soil.new
  end

  def plant(seed_name)
    Seed.new(seed_name, soil: soil)
  end

  def to_s
    "👨‍🌾 #{name}"
  end
end
