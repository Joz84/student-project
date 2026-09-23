class Group < ApplicationRecord
  belongs_to :ue
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :lesson_groups, dependent: :destroy
  has_many :lessons, through: :lesson_groups

  # tp_info : les TP d'informatique suivent un découpage distinct des autres TP.
  enum kind: { td: 0, tp: 1, tp_info: 2, option: 3 }

  validates :label, presence: true, uniqueness: { scope: :ue_id }

  # « TD-01 » -> « TD1 », la forme utilisée jusqu'ici dans users.td / users.tp
  def short_label
    label.sub(/\A(TD|TP)-0*(\d+)/) { "#{$1}#{$2}" }
  end
end
