# frozen_string_literal: true

RSpec.describe 'Clickhouse visitor' do
  let(:model) { ActiveRecord::Base }
  let(:connection) { model.connection }
  let(:visitor) { Arel::Visitors::Clickhouse.new(connection) }

  describe 'map access' do
    let(:table) { Arel::Table.new(:items) }

    it 'renders bracket syntax for a string key' do
      node = Arel::Nodes::MapAccess.new(table[:attrs], Arel.sql("'key'"))

      expect(visitor.compile(node)).to eq("items.attrs['key']")
    end

    it 'renders bracket syntax for a numeric key expression' do
      node = Arel::Nodes::MapAccess.new(table[:counts], Arel.sql('1'))

      expect(visitor.compile(node)).to eq('items.counts[1]')
    end
  end

  describe 'lambda' do
    it 'renders a single-argument lambda' do
      node = Arel::Nodes::Lambda.new('x', Arel.sql('x + 1'))

      expect(visitor.compile(node)).to eq('x -> x + 1')
    end

    it 'renders a multi-argument lambda from an argument list' do
      node = Arel::Nodes::Lambda.new(
        %w[id extension],
        Arel.sql('concat(lower(id), extension)')
      )

      expect(visitor.compile(node)).to eq('(id, extension) -> concat(lower(id), extension)')
    end

    it 'renders a lambda when the signature is a single string' do
      node = Arel::Nodes::Lambda.new(
        '(id, extension)',
        Arel.sql('concat(lower(id), extension)')
      )

      expect(visitor.compile(node)).to eq('(id, extension) -> concat(lower(id), extension)')
    end
  end
end
