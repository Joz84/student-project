class Card < ApplicationRecord
  belongs_to :list
  acts_as_list scope: :list
  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments
  validates :name, presence: true
  validates :description, presence: true

  attr_reader :old_list, :new_list, :old_index, :new_index

  def team
    list&.team
  end

  def str_begin_at
    begin_at ? format_date(begin_at) : nil 
  end

  def str_end_at
    end_at ? format_date(end_at) : nil
  end

  private

  def format_date(date)
    date.strftime("%d/%m/%y") 
  end

end
