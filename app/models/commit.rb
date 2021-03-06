class Commit
  include Mongoid::Document
  include Mongoid::Timestamps
  include ScoreHelper

  COMMIT_TYPE = {score: 'Scores', commit: 'Commits', activity: 'Activities'}

  attr_accessor :branch

  field :message,        type: String
  field :commit_date,    type: DateTime
  field :html_url,       type: String
  field :comments_count, type: Integer, default: 0
  field :sha,            type: String
  field :auto_score,     type: Integer, default: 0
  field :default_score,  type: Float, default: 0
  field :bugspots_score, type: Float, default: 0

  belongs_to :user
  belongs_to :repository
  belongs_to :round
  has_many :comments, as: :commentable
  embeds_many :scores, as: :scorable

  validates :message, uniqueness: {:scope => :commit_date}

  scope :for_round, -> (round_id) { where(:round_id => round_id) }

  index({ user_id: 1, round_id: 1 })
  index({ repository_id: 1 })
  index({ created_at: -1 })
  index({ sha: 1 })

  after_create do |c|
    c.user.inc(commits_count: 1)
  end

  def info
    @info ||= GITHUB.repos.commits.get(repository.owner, repository.name, sha)
  end

  def avg_score
    if self.scores.any?
      scores.pluck(:value).sum/scores.count
    end
  end

  def list_scores
    self.scores.inject(""){|r, s| r += "#{s.user.name}: #{s.rank}<br/>"}
  end

  def judge_rating(user)
    scores.where(user: user).first.try(:value)
  end

end
