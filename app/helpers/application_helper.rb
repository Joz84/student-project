module ApplicationHelper
  def svg_tag(name)
    file_path = "#{Rails.root}/app/assets/images/#{name}.svg"
    if File.exists?(file_path)
       File.read(file_path).html_safe
    else
      '(not found)'
    end
  end

  def render_turbo_stream_flash_messages
    turbo_stream.prepend "flash", partial: "shared/flashes"
  end

  def active_course
    Course.where(ticket_activation: true).last
  end

  def default_course
    Course.find_by(id: session[:course_id]) || 
    active_course ||
    Course.find_by(position: 1)
  end
end
