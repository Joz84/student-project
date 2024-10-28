class AddTicketActivationToCourses < ActiveRecord::Migration[7.1]
  def change
    add_column :courses, :ticket_activation, :boolean
  end
end
