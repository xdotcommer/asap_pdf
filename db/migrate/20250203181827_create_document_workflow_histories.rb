class CreateDocumentWorkflowHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :document_workflow_histories do |t|
      t.references :document, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :status_type
      t.string :from_status
      t.string :to_status
      t.string :action_type
      t.jsonb :metadata
      t.text :notes

      t.timestamps
    end
  end
end
