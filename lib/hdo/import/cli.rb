require 'optparse'

module Hdo
  module Import
    class CLI

      def initialize(argv)
        if argv.empty?
          raise ArgumentError, 'no args'
        else
          @options = {}

          OptionParser.new { |opt|
            opt.on("-s", "--quiet") { @options[:quiet] = true }
            opt.on("-h", "--help") do
              puts opt
              exit 1
            end
          }.parse!(argv)

          @cmd = argv.shift
          @rest = argv
        end
      end

      def run
        case @cmd
        when 'json'
          import_files
        when 'daily'
          raise NotImplementedError
        when 'api'
          import_api
        when 'dev'
          import_api(30)
        when 'representatives'
          import_api_representatives
        else
          raise ArgumentError, "unknown command: #{@cmd.inspect}"
        end
      end

      private

      def import_api(vote_limit = nil)
        persister.import_parties parsing_data_source.parties
        persister.import_committees parsing_data_source.committees
        persister.import_districts parsing_data_source.districts

        import_api_representatives

        persister.import_categories parsing_data_source.categories

        issues = parsing_data_source.issues

        persister.import_issues issues
        persister.import_votes votes_for(parsing_data_source, issues, vote_limit)
      end

      def import_api_representatives
        persister.import_representatives parsing_data_source.representatives
        persister.import_representatives parsing_data_source.representatives_today
      end

      def votes_for(data_source, issues, limit = nil)
        result = []

        issues.each do |issue|
          result += data_source.votes_for(issue.external_id)
          break if limit && result.size >= limit
        end

        result
      end

      def import_files
        @rest.each do |file|
          print "\nimporting #{file}:"

          str = file == "-" ? STDIN.read : File.read(file)
          data = MultiJson.decode(str)

          case data
          when Array
            data.each { |e| import_hash(e) }
          when Hash
            import_hash data
          else
            raise TypeError, "expected Hash or Array, got: #{data.inspect}"
          end
        end
      end

      def import_hash(hash)
        kind = hash['kind'] or raise ArgumentError, "missing 'kind' property: #{hash.inspect}"

        case kind
        when 'hdo#representative'
          persister.import_representative StrortingImporter::Representative.from_hash(hash)
        when 'hdo#party'
          persister.import_party StortingImporter::Party.from_hash(hash)
        when 'hdo#committee'
          persister.import_committee StortingImporter::Committee.from_hash(hash)
        when 'hdo#category'
          persister.import_category StortingImporter::Categories.from_hash(hash)
        when 'hdo#district'
          persister.import_district StortingImporter::District.from_hash(hash)
        when 'hdo#issue'
          persister.import_issue StortingImporter::Issue.from_hash(hash)
        when 'hdo#vote'
          persister.import_vote StortingImporter::Vote.from_hash(hash)
        when 'hdo#promise'
          persister.import_promise StortingImporter::Promise.from_hash(hash)
        else
          raise "unknown type: #{kind}"
        end
      end

      def parsing_data_source
        @parsing_data_source ||= Hdo::StortingImporter::ParsingDataSource.new(api_data_source)
      end

      def api_data_source
        @api_data_source ||= Hdo::StortingImporter::ApiDataSource.new("http://data.stortinget.no")
      end

      def persister
        @persister ||= (
          persister = Persister.new
          persister.log = log

          persister
        )
      end

      def log
        @log ||= (
          if @options[:quiet]
            Logger.new(File::NULL)
          else
            Hdo::StortingImporter.logger
          end
        )
      end

    end # CLI
  end # Import
end # Hdo