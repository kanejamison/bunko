# frozen_string_literal: true

class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :content
      t.references :post_type, null: false, foreign_key: true
      t.string :status, null: false, default: "draft"
      t.datetime :published_at

      # SEO fields (default per roadmap)
      t.string :title_tag
      t.text :meta_description

      # Metrics (default per roadmap)
      t.integer :word_count

      t.timestamps
    end

    add_index :posts, :slug
    add_index :posts, :status
    add_index :posts, :published_at
    add_index :posts, [:post_type_id, :slug], unique: true
  end
end
