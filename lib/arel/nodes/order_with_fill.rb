module Arel # :nodoc: all
  module Nodes
    class OrderWithFill < Ordering
      attr_reader :from_expr, :to_expr, :step_expr

      def initialize(ordering, from: nil, to: nil, step: nil)
        super(ordering)
        @from_expr = coerce_expr(from)
        @to_expr = coerce_expr(to)
        @step_expr = coerce_expr(step)
      end

      def reverse
        self.class.new(expr.reverse, from: from_expr, to: to_expr, step: step_expr)
      end

      def hash
        [self.class, expr, from_expr, to_expr, step_expr].hash
      end

      def eql?(other)
        self.class == other.class &&
          expr == other.expr &&
          from_expr == other.from_expr &&
          to_expr == other.to_expr &&
          step_expr == other.step_expr
      end
      alias == eql?

      def direction
        directional_leaf.direction
      end

      def ascending?
        directional_leaf.ascending?
      end

      def descending?
        directional_leaf.descending?
      end

      private

      def directional_leaf
        o = expr
        o = o.expr while o.is_a?(NullsFirst) || o.is_a?(NullsLast)
        o
      end

      def coerce_expr(value)
        case value
        when nil then nil
        when Arel::Nodes::Node then value
        when String then Arel.sql(value)
        else Arel::Nodes.build_quoted(value)
        end
      end
    end
  end
end
