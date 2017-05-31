# Serve the home page.
get '/' do
  process_it
end

# In the downloads directory and sub-directories, use "index.html" as the default page.
get '/downloads*/' do |dirs|
  redirect "/downloads#{dirs}/index.html"
end

# Serve any request that doesn't start with a '_' or a 'd', so special pages
# (like __sinatra__500.png) will pass through, and so will /downloads.
get /^\/[^_d]/ do
  process_it
end

helpers do
  def process_it
    begin
      tokens = parse_request
      #  logger.info ">>>>>>>PARSED #{tokens.inspect}"
      case tokens[:request_type]
      when :uri
        headers 'Vary' => 'Accept'
        redirect url_to_display(tokens), 303
      when :display_url
        [200, create_headers(tokens), display(tokens)]
      when :no_such_individual
        [404, no_such_individual(tokens)]
      when :no_such_format
        [404, no_such_format(tokens)]
      else
        [404, "BAD REQUEST: #{request.path} ==> #{tokens.inspect}"]
      end
    rescue
      [500, internal_server_error(request, $!)]
    end
  end

  def parse_request
    path = request.path
    path, format = parse_format(path)
    path, localname = parse_localname(path)
    context = parse_context(path)
    uri = assemble_uri(context, localname)
    tokens = {context: context, localname: localname, format: format, uri: uri}

    return tokens.merge(request_type: :no_such_individual) unless known_individual(tokens)
    return tokens.merge(request_type: :uri, format: preferred_format) if format.empty?
    return tokens.merge(request_type: :no_such_format) unless recognized_format(format)
    return tokens.merge(request_type: :display_url)
  end

  def parse_format(path)
    # format appears after the last period.
    remainder, dot, format = path.rpartition('.')
    return [path, ''] if dot.empty?
    return [remainder, format]
  end

  def parse_localname(path)
    # localname appears after the second slash
    remainder, slash, localname = path.rpartition('/')
    return [path, ''] unless remainder.index('/')
    return [remainder, localname]
  end

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

  def ext_to_mime
    {
      'html' => 'text/html',
      'n3' => 'text/n3',
      'nt' => 'application/n-triples',
      'rdf' => 'application/rdf+xml',
      'rj' => 'application/rdf+json',
      'ttl' => 'text/turtle'
    }
  end

  def mime_to_ext
    ext_to_mime.invert
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

  def merge_graph_into_template(tokens, graph)
    template = choose_template(tokens)
    erb template.to_sym, :locals => {:graph => graph, :graph_hash => graph.to_hash, :prefixes => prefixes}
  end

  def choose_template(tokens)
    if tokens[:localname].empty?
      "dataset_#{tokens[:context]}"
    else
      "standard"
    end
  end

  # If request.preferred_type has no preference, it will prefer the first one.
  def preferred_format()
    default_mime = ext_to_mime['ttl']
    mime = request.preferred_type([default_mime] + mime_to_ext.keys)
    if mime && mime_to_ext.has_key?(mime)
      mime_to_ext[mime]
    else
      default_ext
    end
  end

  def known_individual(tokens)
    uri = tokens[:uri]
    if $files.acceptable?(uri)
      $files.exist?(uri)
    else
      false
    end
  end

  def recognized_format(format)
    ext_to_mime.has_key?(format)
  end

  def url_to_display(tokens)
    if tokens[:context].empty?
      "%s.%s" % tokens.values_at(:localname, :format)
    elsif tokens[:localname].empty?
      "%s.%s" % tokens.values_at(:context, :format)
    else
      "%s/%s.%s" % tokens.values_at(:context, :localname, :format)
    end
  end

  def display(tokens)
    contents = $files.read(tokens[:uri])
    graph = RDF::Graph.new << RDF::Reader.for(:turtle).new(contents)
    graph << void_triples(tokens)
    build_the_output(graph, tokens, prefixes)
  end

  def void_triples(tokens)
    s = RDF::URI.new(tokens[:uri])
    p = RDF::URI.new("http://rdfs.org/ns/void#inDataset")
    o = RDF::URI.new('http://draft.ld4l.org/' + tokens[:context])
    RDF::Statement(s, p, o)
  end

  def build_the_output(graph, tokens, prefixes)
    format = tokens[:format]
    case format
    when 'n3', 'ttl'
      RDF::Writer.for(:turtle).dump(graph, nil, :prefixes => prefixes)
    when 'nt'
      RDF::Writer.for(:ntriples).dump(graph)
    when 'rj'
      RDF::JSON::Writer.dump(graph, nil, :prefixes => prefixes)
    when 'html'
      merge_graph_into_template(tokens, graph)
    else # 'rdf'
      RDF::RDFXML::Writer.dump(graph, nil, :prefixes => prefixes)
    end
  end

  def create_headers(tokens)
    {"Content-Type" => ext_to_mime[tokens[:format]] + ';charset=utf-8'}
  end

  def no_such_individual(tokens)
    "No such individual #{tokens.inspect}"
  end

  def no_such_format(tokens)
    "No such format #{tokens[:format]}"
  end

  def internal_server_error(request, ex)
    logit "Internal server error: #{request.path}"
    logit ex
    logit ex.backtrace.join("\n")
    "Internal server error."
  end
  
  def logit(message)
    puts "#{Time.new.strftime('%Y-%m-%d %H:%M:%S')} #{message}"
  end
end

