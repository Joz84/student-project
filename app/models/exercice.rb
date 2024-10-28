class Exercice < ApplicationRecord
  belongs_to :course
  has_many :attempts
  validates :position, presence: true
  validates :name, presence: true
  validates :name, uniqueness: true
  validates :cw_token, presence: true
  # validates :cw_token, uniqueness: true

  def cw_url
    "https://www.codewars.com/kata/#{cw_token}/train/python"
  end

  def level
    9 - kata
  end
end
