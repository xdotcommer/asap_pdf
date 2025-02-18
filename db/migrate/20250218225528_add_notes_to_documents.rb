class AddNotesToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :notes, :text
  end
end
