#!/usr/bin/ruby
require 'libgetopts'
require 'libenumx'
require 'libxmldoc'

module CIAX
  # Db class is for read only databases, which holds all items of database.
  # Key for sub structure(Hash,Array) will be symbol (i.e. :data, :list ..)
  # set() generates HashDb
  # Cache is available
  class Dbi < Hashx; end # DB Item

  # DB class
  class Db < Hashx
    attr_reader :displist
    def initialize(type)
      super()
      @cls_color = 5
      @type = type
      # @displist is Display
      lid = 'list'
      lid += "_#{PROJ}" if PROJ
      # Show site list
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
      if _newest?
        res = _load_cache(id)
      else
        @docs = Xml::Doc.new(@type) unless @docs
        res = _validate_rep(yield(@docs))
        _save_cache(id, res)
      end
      res
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
    def _validate_rep(db)
      res = db.deep_search('\$[_a-z]')
      return db if res.empty?
      cfg_err("Counter remained at [#{res.join('/')}]")
    end

    def _newest?
      if NOCACHE
        verbose { "#{@type}/Cache NOCACHE is set" }
        return false
      elsif !test('e', @marfile)
        verbose { "#{@type}/Cache MAR file(#{@base}) not exist" }
        return false
      else
        newer = _cmp_($LOADED_FEATURES.grep(/#{__dir__}/) + Msg.xmlfiles(@type))
        if newer
          verbose { "#{@type}/Cache File(#{newer}) is newer than cache" }
          verbose { "#{@type}/Cache cache=#{::File::Stat.new(@marfile).mtime}" }
          verbose { "#{@type}/Cache file=#{::File::Stat.new(newer).mtime}" }
          return false
        end
      end
      true
    end

    def _cmp_(ary)
      ary.each do|f|
        return f if ::File.file?(f) && test('>', f, @marfile)
      end
      false
    end

    ####### For Command DB #######

    # Take parameter and next line
    def par2item(doc, item)
      return unless /par_(num|str)/ =~ doc.name
      @argc +=1
      attr = { type: $1, list: doc.text.split(',') }
      attr[:label] = doc[:label] if doc[:label]
      (item[:parameters] ||= []) << attr
    end

    # Check parameter var for subst in db
    def validate_par(db)
      res = db.deep_search(format('\$[%d-9]', @argc+1))
      return db if res.empty?
      cfg_err("Parameter var out of range [#{res.join('/')}] for #{@argc}")
    ensure
      @argc = 0
    end

    def init_command(dbc, dbi)
      @idx = Hashx.new
      @grps = Hashx.new
      @units = Hashx.new
      # Adapt to both XML::Gnu, Hash
      dbc.each_value do|e|
        # e.name should be group
        Msg.give_up('No group in dbc') unless e.name == 'group'
        gid = e.attr2item(@grps)
        _add_unit(e, gid)
      end
      cdb = dbi[:command] = Hashx.new( group: @grps, index: @idx )
      cdb[:unit] = @units unless @units.empty?
      cdb
    end

    def _add_unit(doc, gid)
      return unless doc
      doc.each do|e0|
        case e0.name
        when 'unit'
          uid = e0.attr2item(@units)
          (@grps[gid][:units] ||= []) << uid
          e0.each do|e1|
            id, itm = _add_item(e1, gid)
            itm[:unit] = uid
            (@units[uid][:members] ||= []) << id
          end
        when 'item'
          _add_item(e0, gid)
        end
      end
      self
    end

    def _add_item(doc, gid)
      id = doc.attr2item(@idx)
      (@grps[gid][:members] ||= []) << id
      [id, @idx[id]]
    end
  end
end
