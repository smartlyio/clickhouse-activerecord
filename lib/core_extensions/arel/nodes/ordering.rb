module CoreExtensions
  module Arel # :nodoc: all
    module Nodes
      class Ordering
        def with_fill(from: nil, to: nil, step: nil)
          OrderWithFill.new(self, from: from, to: to, step: step)
        end
      end
    end
  end
end
