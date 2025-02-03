class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :file_name
      t.string :url
      t.integer :file_size
      t.datetime :last_modified_date
      t.string :document_status
      t.string :classification_status
      t.string :policy_review_status
      t.string :recommendation_status
      t.string :status
      t.string :document_category
      t.float :document_category_confidence
      t.text :accessibility_recommendation
      t.text :accessibility_action
      t.datetime :action_taken_on
      t.string :title
      t.string :author
      t.string :subject
      t.string :keywords
      t.datetime :creation_date
      t.datetime :modification_date
      t.string :producer
      t.string :pdf_version
      t.integer :number_of_pages
      t.references :site, null: false, foreign_key: true

      t.timestamps
    end
  end
end
