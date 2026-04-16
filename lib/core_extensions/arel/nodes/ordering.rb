module CoreExtensions
  module Arel # :nodoc: all
    module Nodes
      module Ordering
        def with_fill(from: nil, to: nil, step: nil)
          ::Arel::Nodes::OrderWithFill.new(self, from: from, to: to, step: step)
        end
      end
    end
  end
end
