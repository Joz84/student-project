class Presence < ApplicationRecord
  belongs_to :user
  belongs_to :meeting, inverse_of: :presences

  enum progress: [ :absent, :present, :excused ] 
end
