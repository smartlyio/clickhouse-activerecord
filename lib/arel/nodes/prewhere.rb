module Arel # :nodoc: all
  module Nodes
    # The FROM source of a select (left) and its PREWHERE condition (right).
    class Prewhere < Arel::Nodes::Binary
      delegate :empty?, to: :left
    end
  end
end
