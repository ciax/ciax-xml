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
      super(%i(version command) + ary)
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
      @latest = _get_latest_file
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
      Dbi.new(doc[:attr])
    end

    # Returns Dbi(command list) or Disp(site list)
    def _get_cache(id)
      @base = "#{@type}-#{id}"
      @marfile = vardir('cache') + "#{@base}.mar"
      return _load_cache(id) if _use_cache?
      @docs = Xml::Doc.new(@type, @proj) unless @docs # read xml file
      nil
    end

    def _get_db(id)
      res = _validate_repl(yield(@docs))
      _save_cache(id, res)
    end

    def _get_latest_file
      ary = $LOADED_FEATURES.grep(/#{__dir__}/) + Msg.xmlfiles(@type)
      ary.max_by { |f| File.mtime(f) }
    end

    def _load_cache(id)
      verbose { "Cache Loading (#{id})" }
      return self[id] if key?(id)
      begin
        Marshal.load(IO.read(@marfile))
      rescue ArgumentError # if empty
        Hashx.new
      end
    end

    def _save_cache(id, res)
      verbose { "Cache Refresh (#{id})" }
      open(@marfile, 'w') do |f|
        f << Marshal.dump(res)
        verbose { "Cache Saved(#{id})" }
      end
      self[id] = res
    end

    # counter must not remain
    def _validate_repl(db)
      res = db.deep_search('\$[_a-z]')
      return db if res.empty?
      cfg_err("Counter remained at [#{res.join('/')}]")
    end

    def _use_cache?
      verbose(ENV['NOCACHE']) do
        "#{@type}/Cache ENV['NOCACHE'] is set"
      end || verbose(!test('e', @marfile)) do
        "#{@type}/Cache MAR file(#{@base}) not exist"
      end || verbose(test('>', @latest, @marfile)) do
        "#{@type}/Cache File(#{@latest}) is newer than #{@marfile}"
      end || (return verbose { "#{@type}/Cache Using" })
      false
    end
  end
end
