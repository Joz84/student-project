class Presence < ApplicationRecord
  belongs_to :user
  belongs_to :meeting

  enum progress: [ :absent, :present, :excused ] 
end
