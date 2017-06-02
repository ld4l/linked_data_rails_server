class DatasetController < ApplicationController

  # Return linked data.

  def index
    # Process requests for all triples or all triples for a specific organization.
    process_it
  end

  def standard
    # Process a single URI request.
    process_it
  end

  # Lists the possible downloads with links to the download.
  def download
    redirect "public/downloads/index.html"
  end

  private

    def process_it
      begin
        tokens = parse_request
        logger.info ">>>>>>>PARSED #{tokens.inspect} + request.format=>''#{request.format}''"
        @graph = graph(tokens)
        @graph_hash = @graph.to_hash
        @prefixes = prefixes
        @institution_name = tokens[:context]
        respond_to do |format|
          format.html # index.html.erb or standard.html.erb based on route
          format.n3   { render inline: RDF::Writer.for(:turtle).dump(@graph, nil, :prefixes => @prefixes) }
          format.ttl  { render inline: RDF::Writer.for(:turtle).dump(@graph, nil, :prefixes => @prefixes) }
          format.nt   { render inline: RDF::Writer.for(:ntriples).dump(@graph) }
          format.rj   { render inline: RDF::JSON::Writer.dump(@graph, nil, :prefixes => @prefixes) }
          format.rdf  { render inline: RDF::RDFXML::Writer.dump(@graph, nil, :prefixes => @prefixes) }
        end
      rescue LinkedDataRailsServer::UnknownIndividual => e
        head :not_found, { 'warn-text' => e.message }
        return
      rescue ActionController::UnknownFormat
        head :not_found, { 'warn-text' => no_such_format }
        return
      rescue
        head :internal_server_error, { 'warn-text' => internal_server_error(request, $!) }
        return
      end
    end

    def parse_request
      path = request.path
      path, format = parse_format(path)
      path, localname = parse_localname(path)
      context = parse_context(path)
      uri = assemble_uri(context, localname)
      tokens = {context: context, localname: localname, uri: uri}

      raise LinkedDataRailsServer::UnknownIndividual, no_such_individual(tokens) unless known_individual(tokens)
      tokens
    end

    # Returns format as one of ['n3', 'ttl', 'nt', 'rj', 'html', '']
    def parse_format(path)
      # format appears after the last period.
      remainder, dot, format = path.rpartition('.')
      return [path, ''] if dot.empty?
      return [remainder, format]
    end

    # Returns localname of the URI
    def parse_localname(path)
      # localname appears after the second slash
      remainder, slash, localname = path.rpartition('/')
      return [path, ''] unless remainder.index('/')
      return [remainder, localname]
    end

    # Returns context as [cornell, harvard, stanford]
    def parse_context(path)
      path.chop! if path[-1] == '/'
      if path =~ %r{^/(.+)$}
        $1
      else
        ''
      end
    end

    def assemble_uri(context, localname)
      if context.empty?
        'http://draft.ld4l.org/'
      elsif localname.empty?
        "%s%s" % ['http://draft.ld4l.org/', context]
      else
        "%s%s/%s" % ['http://draft.ld4l.org/', context, localname]
      end
    end

    def prefixes
      {
          ''.to_sym => RDF::URI('http://draft.ld4l.org/') ,
          :dcterms => RDF::URI('http://purl.org/dc/terms/') ,
          :fast => RDF::URI('http://id.worldcat.org/fast/') ,
          :foaf => RDF::URI('http://xmlns.com/foaf/0.1/') ,
          :ld4l => RDF::URI('http://bib.ld4l.org/ontology/'),
          :ld4lcornell => RDF::URI('http://draft.ld4l.org/cornell/'),
          :ld4lharvard => RDF::URI('http://draft.ld4l.org/harvard/'),
          :ld4lstanford => RDF::URI('http://draft.ld4l.org/stanford/'),
          :locclass => RDF::URI('http://id.loc.gov/authorities/classification/'),
          :madsrdf => RDF::URI('http://www.loc.gov/mads/rdf/v1#'),
          :oa => RDF::URI('http://www.w3.org/ns/oa#'),
          :owl => RDF::URI('http://www.w3.org/2002/07/owl#'),
          :prov => RDF::URI('http://www.w3.org/ns/prov#'),
          :rdfs => RDF::URI('http://www.w3.org/2000/01/rdf-schema#') ,
          :skos => RDF::URI('http://www.w3.org/2004/02/skos/core#') ,
          :void => RDF::URI('http://rdfs.org/ns/void#'),
          :worldcat => RDF::URI('http://www.worldcat.org/oclc/'),
          :xsd => RDF::URI('http://www.w3.org/2001/XMLSchema#') ,
      }
    end

    def known_individual(tokens)
      uri = tokens[:uri]
      if $files.acceptable?(uri)
        $files.exist?(uri)
      else
        false
      end
    end

    def graph(tokens)
      contents = $files.read(tokens[:uri])
      graph = RDF::Graph.new << RDF::Reader.for(:turtle).new(contents)
      graph << void_triples(tokens)
    end

    def void_triples(tokens)
      s = RDF::URI.new(tokens[:uri])
      p = RDF::URI.new("http://rdfs.org/ns/void#inDataset")
      o = RDF::URI.new('http://draft.ld4l.org/' + tokens[:context])
      RDF::Statement(s, p, o)
    end

    def no_such_individual(tokens)
      "No such individual #{tokens.inspect}"
    end

    def no_such_format
      "No such format '#{request.format.to_s}'.  Supported formats: '*.html':'text/html', '*.n3':'text/n3', '*.nt':'application/n-triples', '*.rdf':'application/rdf+xml', '*.rj':'application/rdf+json', '*.ttl':'text/turtle'."
    end

    def internal_server_error(request, ex)
      logit "Internal server error: #{request.path}"
      logit ex
      logit ex.backtrace.join("\n")
      "Internal server error."
    end

    def logit(message)
      logger.warn "#{Time.new.strftime('%Y-%m-%d %H:%M:%S')} #{message}"
    end
end

