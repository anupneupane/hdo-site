class Vote < ActiveRecord::Base
  extend FriendlyId

  include Hdo::Model::HasStatsCache
  include Tire::Model::Search
  include Tire::Model::Callbacks

  tire.settings(TireSettings.default) {
    indexes :category_names, index: :not_analyzed
  }

  attr_accessible :for_count, :against_count, :absent_count,
                  :enacted, :personal, :subject, :time, :external_id,
                  :proposition_type

  PROPOSITION_TYPES = I18n.t('app.votes.proposition_types').except(:none).keys.map(&:to_s)
  validates_inclusion_of :proposition_type,
                         in: PROPOSITION_TYPES + [nil, '']

  has_and_belongs_to_many :parliament_issues, uniq: true

  has_many :vote_connections, dependent: :destroy
  has_many :representatives, through: :vote_results, order: :last_name
  has_many :propositions, dependent: :destroy
  has_many :issues, through: :vote_connections
  has_many :vote_results, dependent: :destroy,
                          before_add: :clear_stats_cache,
                          before_remove: :clear_stats_cache

  validates_length_of     :parliament_issues, minimum: 1
  validates_presence_of   :time, :external_id
  validates_uniqueness_of :external_id

  # timestamps are unique unless it's an alternate vote, in which case 'enacted' will not be the same
  validates_uniqueness_of :time, scope: :enacted

  friendly_id :external_id, use: :slugged

  scope :latest,       lambda { |limit| order(:time).reverse_order.limit(limit) }
  scope :personal,     where(:personal => true)
  scope :non_personal, where(:personal => false)
  scope :with_results, includes(:parliament_issues, vote_results: {representative: {party_memberships: :party}})

  def self.naive_search(filter, keyword, selected_categories = [])
    # TODO: elasticsearch
    votes = Vote.includes(:parliament_issues, :propositions, :vote_connections)

    case filter
    when 'selected-categories'
      votes.select! do |v|
        v.parliament_issues.any? { |i| (i.categories & selected_categories).any? }
      end
    when 'not-connected'
      votes.select! { |v| v.vote_connections.empty? }
    else
      # ignore 'all' or others
    end

    if keyword.present?
      votes.select! do |v|
        v.propositions.any? { |e| e.plain_body.include? keyword } ||
          v.parliament_issues.any? { |e| e.description.include? keyword }
      end
    end

    votes.select { |e| e.parliament_issues.all?(&:processed?) }
  end

  def self.admin_search(filter, query, selected_categories = [])
    query = '*' if query.blank?

    opts = {
      load: {
        include: [ :parliament_issues, :issues, :vote_connections ]
      }
    }

    response = search(opts) do |s|
      s.size 1000

      s.query do |q|
        q.filtered do |f|
          f.query { |qr| qr.string query, default_operator: 'AND' }

          f.filter :term, processed: true

          if filter == 'selected-categories'
            f.filter :terms, category_names: selected_categories.map { |e| e.name }
          end
        end
      end
    end

    response.results
  end

  def time_text
    I18n.l time, format: :short
  end

  def proposition_type_text
    I18n.t("app.votes.proposition_types.#{proposition_type}")
  end

  def has_results?
    vote_results.size > 0
  end

  def inferred?
    non_personal? && has_results?
  end

  def non_personal?
    !personal?
  end

  def enacted_text
    enacted? ? I18n.t('app.yes') : I18n.t('app.no')
  end

  def minutes_url
    I18n.t("app.external.urls.minutes") % [ParliamentSession.for_date(time).name, time.strftime("%y%m%d")]
  end

  def alternate_of?(other)
    time == other.time &&
      for_count == other.against_count &&
      against_count == other.for_count &&
      absent_count == other.absent_count &&
      enacted? != other.enacted?
  end

  def to_indexed_json
    # TODO: touch when associations change (+ specs)

    data = as_json(include: {
      propositions:      { only: :description, methods: :plain_body },
      parliament_issues: { only: :description }
    })

    data[:processed] = true
    data[:category_names] = Set.new

    parliament_issues.each do |pi|
      data[:processed] = false unless pi.processed?
      data[:category_names] += pi.categories.map { |e| e.name }
    end

    data.to_json
  end

  private

  def fetch_stats
    Hdo::Stats::VoteCounts.new self
  end

end # Vote
