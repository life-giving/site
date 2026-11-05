# Manual ordering. Including models define #siblings, the relation they are ordered within.
module Positioned
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order(:position, :id) }
    before_create { self.position = (siblings.maximum(:position) || -1) + 1 }
  end

  def move_to(index)
    transaction do
      list = siblings.where.not(id: id).ordered.to_a
      list.insert(index.to_i.clamp(0, list.size), self)
      list.each_with_index { |record, i| record.update_column(:position, i) }
    end
  end
end
