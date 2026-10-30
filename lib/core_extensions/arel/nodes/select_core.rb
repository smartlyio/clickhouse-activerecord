module CoreExtensions
  module Arel # :nodoc: all
    module Nodes
      module SelectCore
        attr_accessor :final, :prewhere

        def source
          source = super
          source = ::Arel::Nodes::Final.new(source) if final
          source = ::Arel::Nodes::Prewhere.new(source, prewhere) if prewhere
          source
        end

        def hash
          [
            @source, @set_quantifier, @projections, @optimizer_hints,
            @wheres, @groups, @havings, @windows, @comment, @final, @prewhere
          ].hash
        end

        def eql?(other)
          super && final == other.final && prewhere == other.prewhere
        end
      end
    end
  end
end
