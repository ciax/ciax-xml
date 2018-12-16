#!/usr/bin/ruby
require 'libhashx'
require 'libxmldoc'

module CIAX
  # Db class is for read only databases, which holds all items of database.
  # Key for sub structure(Hash,Array) will be symbol (i.e. :data, :list ..)
  # set() generates HashDb
  # Cache is available
  class Dbi < Hashx # DB Item
    def pick(ary = [])
      super(%i(layer version) + ary).update(dbi: self)
    end
  end

  # DB class
  class Db < Hashx
    attr_reader :displist
    def initialize(type)
      super()
      verbose { 'Initiate Db' }
      @type = type
      _get_displist
      @argc = 0
    end

    # Reduce valid_keys with parameter Array
    def list(ary = [])
      vk = @displist.valid_keys
      return vk if ary.empty?
      ary &= vk
      vk.replace(ary)
    end

    def get(id)
      ref(id) || id_err(id, @type, @displist)
    end

    # return Dbi
    # Order of file reading: type-id.mar -> type-id.xml (processing)
    def ref(id)
      if @displist.valid?(id)
        self[id] || __get_db(id) { |docs| _doc_to_db(docs.get(id)) }
      else
        warning("No such ID [#{id}]")
        false
      end
    end

    private

    # Returns Hash
    def _doc_to_db(doc)
      Dbi.new(doc[:attr]).update(layer: layer_name)
    end

    def _get_displist(sufx = nil)
      # @displist is Display
      lid = ['list', sufx].join('_')
      # Show site list
      # &:displist = { |e| e.displist }
      @displist = __get_db(lid, &:displist)
    end

    # Returns Dbi(command list) or Disp(site list)
    def _get_cache(id)
      @cbase = "#{@type}-#{id}"
      @cachefile = vardir('cache') + "#{@cbase}.mar"
      return ___load_cache(id) if ___use_cache?
    end

    def __get_db(id)
      res = _get_cache(id)
      return res if res
      is_new = ___load_docs(id)
      verbose { "Building DB (#{id})" }
      res = ___validate_repl(yield(@docs))
      ___save_cache(res) if is_new
      self[id] = res
    end

    def ___load_cache(id)
      verbose { "Cache Loading (#{@cbase})" }
      return self[id] if key?(id)
      begin
        # Used Marshal for symbol keys
        Marshal.load(IO.read(@cachefile))
      rescue ArgumentError # if empty
        Hashx.new
      end
    end

    def ___save_cache(res)
      open(@cachefile, 'w') do |f|
        f << Marshal.dump(res)
        verbose { "Cache Saved (#{@cbase})" }
      end
    end

    def ___load_docs(id)
      verbose { "Cache/Checking @docs (#{@type})" }
      if @docs
        verbose { "Cache/XML files are Already read (#{id}) [#{@type}]" }
        false
      else
        verbose { "Reading XML (#{@type}-#{id})" }
        @docs = _new_docs
      end
    end

    def _new_docs
      Xml::Doc.new(@type)
    end

    # counter must not remain
    def ___validate_repl(db)
      res = db.deep_search('\$[_a-z]')
      return db if res.empty?
      cfg_err("Counter remained at [#{res.join('/')}]")
    end

    def ___use_cache?
      !(___envnocache? || ___marexist? || ___xmlnewer? || ___rbnewer?)
    end

    def ___envnocache?
      verbose(ENV['NOCACHE']) do
        "#{@type}/Cache ENV['NOCACHE'] is set"
      end
    end

    def ___marexist?
      verbose(!test('e', @cachefile)) do
        "#{@type}/Cache MAR file(#{@cbase}) not exist"
      end
    end

    def ___xmlnewer?
      __file_newer?('Xml', Msg.xmlfiles(@type))
    end

    def ___rbnewer?
      __file_newer?('Rb', $LOADED_FEATURES.grep(/#{__dir__}/))
    end

    def __file_newer?(cap, ary)
      latest = ary.max_by { |f| File.mtime(f) }
      verbose(test('>', latest, @cachefile)) do
        format('%s/Cache %s(%s) is newer than (%s)',
               @type, cap, latest.split('/').last, @cbase)
      end
    end
  end
end
