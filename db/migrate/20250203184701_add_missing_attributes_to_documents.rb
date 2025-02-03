class AddMissingAttributesToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :recommended_category, :string
    add_column :documents, :category_confidence, :float
    add_column :documents, :approved_category, :string
    add_column :documents, :changed_category, :string
    add_column :documents, :recommended_accessibility_action, :string
    add_column :documents, :accessibility_confidence, :float
    add_column :documents, :approved_accessibility_action, :string
    add_column :documents, :changed_accessibility_action, :string
  end
end
