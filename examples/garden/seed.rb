# frozen_string_literal: true
#
# The beginning of everything.
# A seed knows its name, when it was planted,
# and how to become something more.

require_relative 'soil'

class Seed
  VARIETIES = %i[lavender foxglove sunflower rose tulip].freeze

  attr_reader :name, :planted_at, :soil

  def initialize(name, soil: nil)
    @name = name
    @planted_at = Time.now
    @soil = soil
  end

  def sprout
    Flower.new(self)
  end

  def viable?
    soil.nil? || soil.fertile?
  end

  def to_s = "🌱 #{name}"

  private

  def expired?
    (Time.now - planted_at) > 86400 * 30  # 30 days
  end
end
