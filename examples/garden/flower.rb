# frozen_string_literal: true
#
# A flower is what a seed becomes.
# It has color, memory of its origin,
# and the ability to be picked.

require_relative 'seed'

class Flower
  attr_reader :seed, :color, :bloomed_at

  PALETTES = {
    lavender:  :violet,
    foxglove:  :crimson,
    sunflower: :gold,
    rose:      :crimson,
    tulip:     :cerulean,
  }.freeze

  def initialize(seed, color: nil)
    @seed  = seed
    @color = color || PALETTES.fetch(seed.name, :white)
    @bloomed_at = Time.now
  end

  def pick
    Basket.new << self
  end

  def to_s
    "#{color} #{seed.name}"
  end
end
