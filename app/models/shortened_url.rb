class ShortenedUrl < ActiveRecord::Base
  include SecureRandom

  validates :short_url, :long_url, presence: true, uniqueness: true
  validate :no_spamming, :nonpremium_max

  def self.random_code
    code = SecureRandom.urlsafe_base64
    while ShortenedUrl.exists?(:short_url => code)
      ShortenedUrl.random_code
    end
    code
  end

  def self.CreateShortenedUrls(user, long_url)
    short_url = ShortenedUrl.random_code
    ShortenedUrl.create!(:short_url => short_url, :long_url => long_url, :user_id => user.id)
  end

  belongs_to :submitter,
    primary_key: :id,
    foreign_key: :user_id,
    class_name: :User

  has_many :visits,
    primary_key: :id,
    foreign_key: :shortened_url_id,
    class_name: :Visit

  has_many :visitors,
    -> { distinct },
    through: :visits,
    source: :user

  has_many :taggings,
    primary_key: :id,
    foreign_key: :shortened_url_id,
    class_name: :Tagging

  has_many :tag_topics,
    through: :taggings,
    source: :topic

  def num_clicks
    self.visits.count
  end

  def num_uniques
    self.visitors.select(:id).count
  end
  def num_recent_uniques
    self.visits.where({ updated_at: (Time.now - 600)..Time.now}).distinct.count(:user_id)
  end

  private

  def no_spamming
    if self.submitter.submitted_urls.where({ created_at: (Time.now - 60)..Time.now}).count >= 5
      errors[:spam] << "can't create more than 5 short urls in a minute"
    end
  end

  def nonpremium_max
    if self.submitter.submitted_urls.count >=5
      errors[:nonpremium] << "can't create more than 5 unless you pay $$$$"
    end
  end
end
