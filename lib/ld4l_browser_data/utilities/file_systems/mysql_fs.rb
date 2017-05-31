require 'mysql2'

module Ld4lBrowserData
  module Utilities
    module FileSystems
      class MySqlFS
        DEFAULT_PARAMS = {
          :host => 'localhost',
          :username => 'SUPPLY_USERNAME',
          :password => 'SUPPLY_PASSWORD',
          :database => 'ld4l',
        }

        def initialize(params)
          @settings = DEFAULT_PARAMS.merge(params)
          @client = Mysql2::Client.new(@settings)
          @insert_statement = @client.prepare('INSERT INTO lod SET uri = ?, rdf = ?')
          @update_statement = @client.prepare('INSERT INTO lod SET uri = ?, rdf = ? ON DUPLICATE KEY UPDATE rdf = ?')
        end

        def get_bookmark(key)
          result = @read_statement.execute('bookmark_' + key)
          row = result.first
          if row && row['rdf']
            bkmk = JSON.parse(row['rdf'], :symbolize_names => true)
            bkmk
          else
            nil
          end
        end

        def set_bookmark(key, contents)
          insert('bookmark_' + key, JSON.generate(contents))
        end

        def acceptable?(uri)
          true
        end

        def exist?(uri)
          true && get_rdf_for_uri(uri)
        end

        def exists?(uri)
          exist?(uri)
        end

        def read(uri)
          select(uri)
        end

        def select(uri)
          get_rdf_for_uri(uri)
        end

        def write(uri, contents)
          insert(uri, contents)
        end

        def insert(uri, rdf)
          begin
            @insert_statement.execute(uri, rdf)
          rescue
            @update_statement.execute(uri, rdf, rdf)
          end
        end

        def close()
          @client.close
        end

        def get_rdf_for_uri(uri)
          client = Mysql2::Client.new(@settings)
          read_statement = client.prepare('SELECT rdf FROM lod WHERE uri = ?')
          row = read_statement.execute(uri).first
          if row
            row['rdf']
          else
            nil
          end
        end
      end
    end
  end
end
=begin
This is sloppy. I should convert the insert and update to use a fresh client each time, like the read now does.
On the other hand, I haven't had any problem with the insert and update (OR HAVE I?)
=end
