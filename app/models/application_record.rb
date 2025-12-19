class ApplicationRecord < ActiveRecord::Base
  include TranslatableAssociations
  primary_abstract_class
end
