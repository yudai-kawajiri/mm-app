class ProductPlan < ApplicationRecord
  belongs_to :plan
  belongs_to :product
end
