# frozen_string_literal: true

RSpec.describe 'Clickhouse visitor' do
  let(:connection) { ActiveRecord::Base.connection }

  # A single visitor instance is reused, mirroring how ActiveRecord memoizes
  # one visitor per connection and reuses it for every query.
  let(:visitor) { Arel::Visitors::Clickhouse.new(connection) }

  describe 'delete_or_update flag isolation (issue #243)' do
    let(:authors) { Arel::Table.new(:authors) }
    let(:books)   { Arel::Table.new(:books) }

    # Mirrors Arel::TreeManager#to_sql, which calls #accept (not #compile).
    def accept(node)
      visitor.accept(node, Arel::Collectors::SQLString.new).value
    end

    let(:select_ast) do
      authors
        .project(authors[:id], books[:title])
        .join(books).on(authors[:id].eq(books[:author_id]))
        .ast
    end

    let(:expected_select) do
      'SELECT authors.id, books.title FROM authors INNER JOIN books ON authors.id = books.author_id'
    end

    let(:update_ast) do
      manager = Arel::UpdateManager.new
      manager.table(authors)
      manager.set([[authors[:name], 'George Orwell']])
      manager.where(authors[:id].eq(1))
      manager.ast
    end

    let(:delete_ast) do
      manager = Arel::DeleteManager.new
      manager.from(authors)
      manager.where(authors[:id].eq(1))
      manager.ast
    end

    it 'keeps table qualifiers on a SELECT accepted after an UPDATE' do
      accept(update_ast)

      expect(accept(select_ast)).to eq(expected_select)
    end

    it 'keeps table qualifiers on a SELECT accepted after a DELETE' do
      accept(delete_ast)

      expect(accept(select_ast)).to eq(expected_select)
    end

    it 'still renders UPDATE columns without table qualifiers' do
      expect(accept(update_ast))
        .to eq("ALTER TABLE authors UPDATE name = 'George Orwell' WHERE id = 1")
    end

    it 'still renders DELETE columns without table qualifiers' do
      expect(accept(delete_ast)).to eq('DELETE FROM authors WHERE id = 1')
    end
  end
end
