module CoreExtensions
  module Arel
    module SelectManager

      def final!
        @ctx.final = true
        self
      end

      # Adds a condition to the PREWHERE clause, which ClickHouse evaluates before reading the other columns of the
      # select. Conditions of repeated calls are combined with AND. Under FINAL, PREWHERE filters rows before they
      # are deduplicated, so it may only read columns that are equal in every version of a row.
      #
      #   table.project(Arel.star).final!.prewhere(table[:account_id].eq(1)).where(table[:name].eq('a'))
      #   # SELECT * FROM t FINAL PREWHERE t.account_id = 1 WHERE t.name = 'a'
      #
      # @param [Arel::Nodes::Node, String] condition
      def prewhere(condition)
        condition = ::Arel.sql(condition) if condition.is_a?(String)
        @ctx.prewhere = @ctx.prewhere ? ::Arel::Nodes::And.new([@ctx.prewhere, condition]) : condition
        self
      end

      # @param [Hash] values
      def settings(values)
        @ast.settings = ::Arel::Nodes::Settings.new(values)
        self
      end

      # @param [Array] windows
      def windows(windows)
        @ctx.windows = windows.map do |name, opts|
          # https://github.com/rails/rails/blob/main/activerecord/test/cases/arel/select_manager_test.rb#L790
          window = ::Arel::Nodes::NamedWindow.new(name)
          opts.each do |key, value|
            window.send(key, value)
          end
          window
        end
      end

      def using(*exprs)
        @ctx.source.right.last.right = ::Arel::Nodes::Using.new(::Arel.sql(exprs.join(',')))
        self
      end

      def limit_by(*exprs)
        @ast.limit_by = ::Arel::Nodes::LimitBy.new(*exprs)
        self
      end
    end
  end
end
