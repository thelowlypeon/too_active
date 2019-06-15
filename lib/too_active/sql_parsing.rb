module TooActive
  module SqlParsing
    VERB_FINDER = /^['"\s]*(?<verb>\w+)['"\s]*/i.freeze

    class AbstractQuery
      attr_reader :sql, :tablename, :binds

      class << self
        attr_reader :verb, :extractions

        def query_types
          @query_types ||= {
            schema: SchemaQuery,
            select: SelectQuery,
            count: CountQuery,
            update: UpdateQuery,
            insert: InsertQuery,
            delete: DeleteQuery
          }
        end

        def type(v)
          @verb = v
        end

        def components(*comp)
          @extractions = comp
          @extractions.each { |attr| attr_reader attr }
        end

        def from_sql(sql, binds = [])
          sql = sql.gsub(';', '') if sql
          matched_verb = (VERB_FINDER.match(sql) || {})[:verb]
          verb = matched_verb.downcase.to_sym if matched_verb
          if verb == :select && sql.to_s =~ /COUNT/
            verb = :count
          end
          query = query_types[verb] || UnrecognizedQuery
          query.new(sql, binds)
        end
      end

      def initialize(sql, binds = [])
        @sql = sql || ''
        @binds = binds
        extract_parts!
      end

      def verb
        self.class.verb
      end

      def description
        pretty_verb
      end

      private

      def pretty_verb
        verb.to_s.upcase
      end

      def pretty_binds
        binds.map { |bind| "#{bind[0]}:#{bind[1]}" }.join(', ') if binds
      end

      def extract_parts!
        query = sql
        (self.class.extractions || []).reverse.each do |meth|
          query = self.send("extract_#{meth}", query)
        end
      end

      def extract_limit(query)
        (query, @limit) = query.split(/ limit /i)
        @limit = @limit.to_i if @limit
        query
      end

      def extract_conditions(query)
        (query, where) = query.split(/ where /i)
        @conditions = where.split(' AND ') if where
        query
      end
    end

    class TableBasedQuery < AbstractQuery
      attr_reader :tablename

      def description
        "#{tablename} #{verb.to_s.upcase}"
      end
    end

    class SchemaQuery < AbstractQuery
      type :schema
    end

    class UnrecognizedQuery < AbstractQuery
      type :unknown
      components :verb

      def extract_verb(query)
        first_word = query.split(/\s+/)[0]
        @verb = first_word.downcase.to_sym if first_word
      end
    end

    class SelectQuery < TableBasedQuery
      type :select
      components :selects, :tablename, :joins, :conditions, :groups, :orders, :limit

      def description
        if (conditions && conditions.count > 0) || (joins && joins.count > 0) || binds
          tables = [tablename] + (joins || [])
          [tables.join(', '), pretty_conditions].compact.join(': ')
        else
          super
        end
      end

      private

      def pretty_conditions
        if binds
          pretty_binds
        elsif conditions
          conditions.join(',')
        end
      end

      def extract_selects(query)
        select = query.split(/^select /i).last
        @selects = select.split(',').map(&:strip)
        nil
      end

      def extract_groups(query)
        (query, group) = query.split(/ group by /i)
        @groups = group.split(', ') if group
        query
      end

      def extract_orders(query)
        (query, order) = query.split(/ order by /i)
        @orders = order.split(', ') if order
        query
      end

      def extract_joins(query)
        index = query.index(/inner|outer|left|right|join/i)
        if index
          join_clauses = query[index, query.length - index].split(/inner|outer|left|right|join/i)
          @joins = join_clauses
            .select { |join| join && join.strip != '' }
            .map { |join| join.split('ON').first }
            .map(&:strip)
          query[0, index]
        else
          query
        end
      end

      def extract_tablename(query)
        (query, from) = query.split(/ from /i)
        @tablename = from.gsub('"', '').strip
        query
      end
    end

    class CountQuery < SelectQuery
      type :count

      components :selects, :tablename, :conditions, :groups
    end

    class UpdateQuery < TableBasedQuery
      type :update
      components :tablename, :updates, :conditions

      private

      def extract_tablename(query)
        @tablename = query.split(/^update /i).last.gsub('"', '')
        nil
      end

      def extract_updates(query)
        (query, updates) = query.split(/ set /i)
        @updates = updates.split(',')
        query
      end
    end

    class InsertQuery < TableBasedQuery
      type :insert
      components :tablename, :values

      def values_hash
        @values_hash ||= begin
          extract_values(sql) unless @values
          matches = /\((?<columns>[^\)]+)\) values \((?<values>[^\_]+)\)/i.match(@values)
          columns = matches[:columns].split(',') if matches[:columns]
          values = matches[:values].split(',') if matches[:values]
          if columns && values && columns.length == values.length
            hash = {}
            columns.each_with_index do |c, i|
              column = c.strip.to_sym
              value = values[i]
              if value.include?("'")
                hash[column] = value.gsub("'", '')
              elsif values[i].include?('.')
                hash[column] = value.to_f
              else
                hash[column] = value.to_i
              end
            end
            hash
          else
            {}
          end
        end
      end

      private

      def extract_tablename(query)
        @tablename = query.split(/^insert into /i).last.strip
        nil
      end

      def extract_values(query)
        index = query.index('(')
        @values = query[index, query.length - index]
        query[0, index]
      end
    end

    class DeleteQuery < TableBasedQuery
      type :delete
      components :tablename, :conditions

      def extract_tablename(query)
        (query, from) = query.split(/ from /i)
        @tablename = from.gsub('"', '') # this includes joins TODO
        query
      end
    end
  end
end
