class TagTopic < ApplicationRecord
  validates :topic, presence: true

  has_many :taggings,
    primary_key: :id,
    foreign_key: :topic_id,
    class_name: :Tagging

  has_many :urls,
    through: :taggings,
    source: :shortened_url

  def popular_links
    urls = self.urls.limit(5).sort { |a, b| b.num_clicks <=> a.num_clicks }
    urls.each {|url| p "#{url.long_url} has #{url.num_clicks} clicks" }
  end
end
