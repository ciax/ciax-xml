#!/usr/bin/ruby
require 'libenumx'
require 'libxmldoc'

module CIAX
  # Db class is for read only databases, which holds all items of database.
  # Key for sub structure(Hash,Array) will be symbol (i.e. :data, :list ..)
  # set() generates HashDb
  # Cache is available
  class Dbi < Hashx # DB Item
    def pick(ary = [])
      super(%i(layer version command) + ary)
    end
  end

  # DB class
  class Db < Hashx
    attr_reader :displist
    def initialize(type, proj = nil)
      super()
      @type = type
      @proj = proj
      # @displist is Display
      lid = proj ? "list_#{proj}" : 'list'
      # Show site list
      @displist = _get_cache(lid) || _get_db(lid, &:displist) # site list
      @argc = 0
    end

    # return Dbi
    def get(id)
      @displist.valid?(id) ||
        id_err(id, @type, @displist)
      _get_cache(id) || _get_db(id) { |docs| doc_to_db(docs.get(id)) }
    end

    private

    # Returns Hash
    def doc_to_db(doc)
      Dbi.new(doc[:attr]).update(layer: layer_name)
    end

    # Returns Dbi(command list) or Disp(site list)
    def _get_cache(id)
      @cbase = "#{@type}-#{id}"
      @cachefile = vardir('cache') + "#{@cbase}.mar"
      return _load_cache_(id) if _use_cache_?
      @docs = Xml::Doc.new(@type, @proj) unless @docs # read xml file
      nil
    end

    def _get_db(id)
      res = _validate_repl_(yield(@docs))
      _save_cache_(id, res)
    end

    def _get_latest_xmlfile_
      ary = Msg.xmlfiles(@type)
      ary.max_by { |f| File.mtime(f) }
    end

    def _get_rbfiles_
      ary = $LOADED_FEATURES.grep(/#{__dir__}/)
      ary.max_by { |f| File.mtime(f) }
    end

    def _load_cache_(id)
      verbose { "Cache Loading (#{@cbase})" }
      return self[id] if key?(id)
      begin
        # Used Marshal for symbol keys
        Marshal.load(IO.read(@cachefile))
      rescue ArgumentError # if empty
        Hashx.new
      end
    end

    def _save_cache_(id, res)
      open(@cachefile, 'w') do |f|
        f << Marshal.dump(res)
        verbose { "Cache Saved (#{@cbase})" }
      end
      self[id] = res
    end

    # counter must not remain
    def _validate_repl_(db)
      res = db.deep_search('\$[_a-z]')
      return db if res.empty?
      cfg_err("Counter remained at [#{res.join('/')}]")
    end

    def _use_cache_?
      !(_env_nocache? || _mar_exist? || _xml_newer?)
    end

    def _env_nocache?
      verbose(ENV['NOCACHE']) do
        "#{@type}/Cache ENV['NOCACHE'] is set"
      end
    end

    def _mar_exist?
      verbose(!test('e', @cachefile)) do
        "#{@type}/Cache MAR file(#{@cbase}) not exist"
      end
    end

    def _xml_newer?
      latest = _get_latest_xmlfile_
      verbose(test('>', latest, @cachefile)) do
        "#{@type}/Cache Xml(#{latest}) is newer than (#{@cbase})"
      end
    end

    def _rb_newer?
      latest = _get_latest_rbfiles_
      verbose(test('>', latest, @cachefile)) do
        "#{@type}/Cache Rb(#{latest}) is newer than (#{@cbase})"
      end
    end
  end
end
