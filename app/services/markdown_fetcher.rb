# app/services/markdown_fetcher.rb
require 'httparty'
require 'redcarpet'

class MarkdownFetcher
  def initialize(course)
    @url = "https://raw.githubusercontent.com/Joz84/upf-programmation/refs/heads/main/courses/course#{course.position}.md"
  end

  def run
    response = HTTParty.get(@url)
    return unless response.success?
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(response.body).html_safe
  end
end
