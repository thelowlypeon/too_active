module TooActive
  module SqlParsing
    VERB_FINDER = /^['"\s]*(?<verb>\w+)['"\s]*/i.freeze

    class AbstractQuery
      attr_reader :sql, :tablename

      class << self
        attr_reader :verb, :extractions

        def query_types
          @query_types ||= {
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

        def from_sql(sql)
          sql = sql&.gsub(';', '')
          matched_verb = (VERB_FINDER.match(sql) || {})[:verb]
          verb = matched_verb.downcase.to_sym if matched_verb
          if verb == :select && sql.to_s =~ /COUNT/
            verb = :count
          end
          query = query_types[verb] || UnrecognizedQuery
          query.new(sql)
        end
      end

      def initialize(sql)
        @sql = sql || ''
        extract_parts!
      end

      def verb
        self.class.verb
      end

      def description
        "#{tablename} #{verb.to_s.upcase}"
      end

      private

      def extract_parts!
        query = sql
        self.class.extractions.reverse.each do |meth|
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

    class SelectQuery < AbstractQuery
      type :select
      components :selects, :tablename, :joins, :conditions, :groups, :orders, :limit

      def find?
        if conditions && conditions.count == 1
          match = /id["']?\s+=\s+(?<id>\d+)/.match(conditions.first)
          match[:id].to_i if match
        else
          false
        end
      end

      def description
        found_id = find?
        if found_id
          "#{tablename} id:#{found_id}"
        elsif (conditions && conditions.count > 0) || (joins && joins.count > 0)
          tables = [tablename] + (joins || [])
          added_conditions = ": #{conditions.join(',')}" if conditions
          "#{tables.join(', ')}#{added_conditions}"
        else
          super
        end
      end

      private

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

    class UpdateQuery < AbstractQuery
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

    class InsertQuery < AbstractQuery
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

    class DeleteQuery < AbstractQuery
      type :delete
      components :tablename, :conditions

      def extract_tablename(query)
        (query, from) = query.split(/ from /i)
        @tablename = from.gsub('"', '') # this includes joins TODO
        query
      end
    end

    class UnrecognizedQuery < AbstractQuery
      type :unknown
      components :verb

      def extract_verb(query)
        @verb = query.split(/\s+/)[0]&.downcase&.to_sym
      end
    end
  end
end
