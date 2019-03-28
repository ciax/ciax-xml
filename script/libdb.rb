#!/usr/bin/env ruby
require 'libxmldoc'

module CIAX
  # Db class is for read only databases, which holds all items of database.
  # Key for sub structure(Hash,Array) will be symbol (i.e. :data, :list, :dic..)
  # set() generates HashDb
  # Cache is available
  class Dbi < Hashx # DB Item
    def pick(ary = [])
      super(%i(layer version) + ary).update(dbi: self)
    end
  end

  # DB class
  class Db < Hashx
    attr_reader :disp_dic
    def initialize(type)
      super()
      verbose { 'Initiate Db' }
      @type = type
      @cache = Cache.new(type)
      _get_disp_dic
      @argc = 0
    end

    # Reduce valid_keys with parameter Array
    def list(ary = [])
      vk = @disp_dic.valid_keys
      return vk if ary.empty?
      ary &= vk
      vk.replace(ary)
    end

    def get(id)
      ref(id) || id_err(id, @type, @disp_dic)
    end

    # return Dbi
    # Order of file reading: type-id.mar -> type-id.xml (processing)
    def ref(id)
      if @disp_dic.valid?(id)
        self[id] || __get_db(id) { |docs| _doc_to_db(docs.get(id)) }
      else
        warning("No such ID [#{id}]")
        false
      end
    end

    # For instance/device Db
    def run_list
      @disp_dic.valid_keys.select do |id|
        atrb = get(id) || @docs.get(id)[:attr]
        host = atrb[:host]
        atrb[:run] != 'false' && ['localhost', HOST].include?(host)
      end
    end

    private

    # Returns Hash
    def _doc_to_db(doc)
      Dbi.new(doc[:attr]).update(layer: layer_name)
    end

    def _get_disp_dic(sufx = nil)
      # @disp_dic is Display
      lid = ['list', sufx].compact.join('_')
      # Show site list
      # &:disp_dic = { |e| e.disp_dic }
      @disp_dic = __get_db(lid, &:disp_dic)
    end

    def __get_db(id)
      @cache.get(id) do
        ___load_docs(id)
        verbose { "Building DB (#{id})" }
        self[id] = ___validate_repl(yield(@docs))
      end
    end

    # counter must not remain
    def ___validate_repl(db)
      res = db.deep_search('\$[_a-z]')
      return db if res.empty?
      cfg_err("Counter remained at [#{res.join('/')}]")
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
  end

  # DB Cache
  class Cache
    include Msg
    def initialize(type)
      super()
      verbose { 'Initiate Cache' }
      @type = type
    end

    # Returns Dbi(command list) or Disp(site list)
    def get(id)
      @cbase = "#{@type}-#{id}"
      @cachefile = vardir('cache') + "#{@cbase}.mar"
      if ___use_cache?
        ___load_cache
      else
        ___save_cache(yield)
      end
    end

    private

    def ___save_cache(res)
      open(@cachefile, 'w') do |f|
        f << Marshal.dump(res)
        verbose { "Saved (#{@cbase})" }
      end
      res
    end

    def ___load_cache
      verbose { "Loading (#{@cbase})" }
      begin
        # Used Marshal for symbol keys
        Marshal.load(IO.read(@cachefile))
      rescue ArgumentError # if empty
        Hashx.new
      end
    end

    # To scan all
    def ___use_cache?
      !(___envnocache? || ___nomar? || ___xmlnewer? || ___rbnewer?)
    end

    def ___envnocache?
      return unless ENV['NOCACHE']
      verbose { "#{@type} ENV['NOCACHE'] is set" }
      true
    end

    def ___nomar?
      return if test('e', @cachefile)
      verbose { "#{@type} MAR file(#{@cbase}) not exist" }
      true
    end

    def ___xmlnewer?
      __file_newer?('Xml', Msg.xmlfiles(@type))
    end

    def ___rbnewer?
      __file_newer?('Rb', $LOADED_FEATURES.grep(/#{__dir__}/))
    end

    def __file_newer?(cap, ary)
      latest = ary.max_by { |f| File.mtime(f) }
      return unless test('>', latest, @cachefile)
      verbose do
        format('%s %s(%s) is newer than (%s)',
               @type, cap, latest.split('/').last, @cbase)
      end
      true
    end
  end
end
