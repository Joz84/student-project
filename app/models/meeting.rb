class Meeting < ApplicationRecord
  belongs_to :team
  belongs_to :referential
  has_many :presences, dependent: :destroy

  enum progress: [ :past ] 
end
