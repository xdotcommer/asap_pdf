class AddLastModifiedToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :last_modified, :datetime
  end
end
