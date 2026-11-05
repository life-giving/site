class CreateContent < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_users do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :password_digest, null: false
      t.timestamps
    end

    create_table :news_items do |t|
      t.date :date, null: false, index: true
      t.string :title_uk, null: false
      t.string :title_en
      t.text :body_uk
      t.text :body_en
      t.timestamps
    end

    create_table :news_images do |t|
      t.references :news_item, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string :caption
      t.timestamps
    end

    create_table :reports do |t|
      t.string :title_uk, null: false
      t.string :title_en
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
