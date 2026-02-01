# frozen_string_literal: true
#
# A basket collects flowers.
# It includes Enumerable — define `each`, get 60 methods free.
# This is Ruby's philosophy of generosity.

require_relative 'flower'

class Basket
  include Enumerable

  def initialize
    @flowers = []
  end

  def <<(flower)
    @flowers << flower
    self  # return self for chaining — Ruby idiom
  end

  def each(&block)
    @flowers.each(&block)
  end

  def bouquet
    group_by(&:color).transform_values(&:size)
  end

  def to_s = "🧺 #{count} flowers: #{map(&:to_s).join(', ')}"
end
