# frozen_string_literal: true

class PostType < ApplicationRecord
  has_many :posts, dependent: :restrict_with_error

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
