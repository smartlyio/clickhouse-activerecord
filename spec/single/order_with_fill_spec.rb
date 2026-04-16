# frozen_string_literal: true

RSpec.describe 'Order WITH FILL' do
  let(:model) { ActiveRecord::Base }
  let(:connection) { model.connection }
  let(:visitor) { Arel::Visitors::Clickhouse.new(connection) }
  let(:table) { Arel::Table.new(:items) }

  def compile(ordering)
    visitor.compile(ordering)
  end

  describe '#with_fill' do
    it 'wraps the ordering in OrderWithFill' do
      base = table[:created_at].desc
      node = base.with_fill

      expect(node).to be_a(Arel::Nodes::OrderWithFill)
      expect(node.expr).to eq(base)
    end

    it 'renders WITH FILL with no bounds' do
      node = table[:created_at].desc.with_fill

      expect(compile(node)).to eq('items.created_at DESC WITH FILL')
    end

    it 'renders FROM, TO, and STEP when given' do
      node = table[:created_at].desc.with_fill(from: 0, to: 10, step: 2)

      expect(compile(node)).to eq('items.created_at DESC WITH FILL FROM 0 TO 10 STEP 2')
    end

    it 'renders only FROM when the others are omitted' do
      node = table[:created_at].asc.with_fill(from: 1)

      expect(compile(node)).to eq('items.created_at ASC WITH FILL FROM 1')
    end

    it 'accepts a raw SQL fragment for bounds' do
      node = table[:created_at].desc.with_fill(from: Arel.sql('toDateTime(\'2020-01-01\')'))

      expect(compile(node)).to eq(
        "items.created_at DESC WITH FILL FROM toDateTime('2020-01-01')"
      )
    end
  end

  describe 'Arel::Nodes::OrderWithFill' do
    let(:base) { table[:id].asc }

    it '#reverse preserves fill expressions' do
      node = base.with_fill(from: 0, to: 100, step: 10)
      reversed = node.reverse

      expect(reversed).to be_a(Arel::Nodes::OrderWithFill)
      expect(compile(reversed)).to eq('items.id DESC WITH FILL FROM 0 TO 100 STEP 10')
    end

    it 'implements value equality' do
      a = base.with_fill(from: 1, to: 2)
      b = base.with_fill(from: 1, to: 2)
      c = base.with_fill(from: 1, to: 3)

      expect(a).to eq(b)
      expect(a).not_to eq(c)
      expect(a.hash).to eq(b.hash)
    end
  end
end
