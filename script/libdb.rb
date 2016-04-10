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
    def initialize(type)
      super()
      @type = type
      # @displist is Display
      lid = 'list'
      lid += "_#{ENV['PROJ']}" if ENV['PROJ']
      # Show site list
      @latest = _get_latest_file
      @displist = cache(lid, &:displist)
      @argc = 0
    end

    def get(id)
      if @displist.valid?(id)
        cache(id) { |docs| doc_to_db(docs.get(id)) }
      else
        fail(InvalidID, "No such ID (#{id}) in #{@type}\n" + @displist.to_s)
      end
    end

    private

    # Returns Hash
    def doc_to_db(doc)
      Dbi.new(doc[:attr])
    end

    # Returns Dbi(command list) or Disp(site list)
    def cache(id)
      @base = "#{@type}-#{id}"
      @marfile = vardir('cache') + "#{@base}.mar"
      if _get_cache?
        res = _load_cache(id)
      else
        @docs = Xml::Doc.new(@type) unless @docs
        res = _validate_repl(yield(@docs))
        _save_cache(id, res)
      end
      res
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
      open(@marfile, 'w') do|f|
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

    def _get_cache?
      if ENV['NOCACHE']
        verbose { "#{@type}/Cache ENV['NOCACHE'] is set" }
      elsif !test('e', @marfile)
        verbose { "#{@type}/Cache MAR file(#{@base}) not exist" }
      elsif test('>', @latest, @marfile)
        verbose { "#{@type}/Cache File(#{@latest}) is newer than #{@marfile}" }
      else
        true
      end
      false
    end
  end
end
