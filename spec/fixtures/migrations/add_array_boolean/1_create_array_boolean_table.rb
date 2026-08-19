# frozen_string_literal: true

class CreateArrayBooleanTable < ActiveRecord::Migration[7.1]
  def up
    create_table :array_boolean_test, options: 'MergeTree ORDER BY date', force: true do |t|
      t.column :array_boolean, 'Array(Bool)', null: false
      t.date :date, null: false
    end
  end
end
