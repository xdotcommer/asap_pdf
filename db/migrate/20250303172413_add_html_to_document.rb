class AddHtmlToDocument < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :html, :text
  end
end
