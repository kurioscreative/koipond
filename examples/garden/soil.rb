# frozen_string_literal: true
#
# Soil is the foundation.
# It has nutrients, moisture, and pH.
# Some seeds need specific conditions.

class Soil
  attr_reader :nutrients, :moisture, :ph

  def initialize(nutrients: 0.5, moisture: 0.5, ph: 7.0)
    @nutrients = nutrients
    @moisture = moisture
    @ph = ph
  end

  def fertile?
    nutrients > 0.3 && moisture > 0.2
  end

  def water!(amount = 0.1)
    @moisture = [@moisture + amount, 1.0].min
    self
  end

  def fertilize!(amount = 0.1)
    @nutrients = [@nutrients + amount, 1.0].min
    self
  end

  def to_s
    "Soil(n=#{nutrients}, m=#{moisture}, ph=#{ph})"
  end
end
