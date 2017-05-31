require 'mysql2'
require 'zlib'

module Ld4lBrowserData
  module Utilities
    module FileSystems
      class MySqlZipFS < MySqlFS
        def write(uri, contents)
          zipped = Zlib.deflate(contents)
          insert(uri, zipped)
        end

        def read(uri)
          contents = select(uri)
          if contents
            Zlib.inflate(contents)
          else
            nil
          end
        end
      end
    end
  end
end