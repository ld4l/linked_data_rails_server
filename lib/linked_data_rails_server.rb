require 'rdf'
require 'rdf/json'
require 'rdf/rdfxml'
require 'rdf/turtle'
require 'zlib'
require 'tilt/erubis'

require 'linked_data_rails_server/file_systems'
# require 'linked_data_rails_server/process_arguments'

module Kernel
  def bogus(message)
    puts(">>>>>>>>>>>>>BOGUS #{message}")
  end
end

module LinkedDataRailsServer
  # You screwed up the calling sequence.
  class IllegalStateError < StandardError
  end

  # What did you ask for?
  class UserInputError < StandardError
  end

  # Raised when the requested file supporting the response does not exist
  class UnknownIndividual < StandardError; end
end
