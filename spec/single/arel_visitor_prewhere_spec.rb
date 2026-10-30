# frozen_string_literal: true

RSpec.describe 'Clickhouse visitor PREWHERE' do
  let(:table) { Arel::Table.new(:items) }
  let(:other) { Arel::Table.new(:others) }
  let(:query) { table.project(table[:id]) }

  it 'renders PREWHERE before WHERE' do
    sql = query.prewhere(table[:account_id].eq(1)).where(table[:name].eq('a')).to_sql

    expect(sql).to eq("SELECT items.id FROM items PREWHERE items.account_id = 1 WHERE items.name = 'a'")
  end

  it 'renders PREWHERE after FINAL and the joins' do
    sql = query.join(other).on(other[:id].eq(table[:other_id])).final!.prewhere(table[:account_id].eq(1)).to_sql

    expect(sql).to eq(
      'SELECT items.id FROM items FINAL INNER JOIN others ON others.id = items.other_id PREWHERE items.account_id = 1'
    )
  end

  it 'combines repeated conditions with AND' do
    sql = query.prewhere(table[:account_id].eq(1)).prewhere('items.id > 2').to_sql

    expect(sql).to eq('SELECT items.id FROM items PREWHERE items.account_id = 1 AND items.id > 2')
  end

  it 'renders a subquery condition' do
    subquery = other.project(other[:id])
    sql = query.prewhere(table[:other_id].in(subquery)).to_sql

    expect(sql).to eq('SELECT items.id FROM items PREWHERE items.other_id IN (SELECT others.id FROM others)')
  end
end
