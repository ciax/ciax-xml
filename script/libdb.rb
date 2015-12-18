#!/usr/bin/ruby
require 'libgetopts'
require 'libenumx'
require 'libxmldoc'

module CIAX
  # Db class is for read only databases, which holds all items of database.
  # Key for sub structure(Hash,Array) will be symbol (i.e. :data, :list ..)
  # set() generates HashDb
  # Cache is available
  class Dbi < Hashx # DB Item
    # cover() will deeply merge self and given db
    # (If end of the element confricts, self content will be taken)
    def cover(db)
      type?(db, Dbi)
      tmp = db.deep_copy.deep_update(self)
      deep_update(tmp)
    end
  end

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
      if newest?
        res = _load_cache(id)
      else
        @docs = Xml::Doc.new(@type) unless @docs
        res = yield(@docs)
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
        {}
      end
    end

    def _save_cache(id, res)
      warning("Cache Refresh (#{id})")
      open(@marfile, 'w') do|f|
        f << Marshal.dump(res)
        verbose { "Cache Saved(#{id})" }
      end
      self[id] = res
    end

    def newest?
      if NOCACHE
        verbose { "#{@type}/Cache NOCACHE is set" }
        return false
      elsif !test('e', @marfile)
        verbose { "#{@type}/Cache MAR file(#{@base}) not exist" }
        return false
      else
        newer = cmp($LOADED_FEATURES.grep(/#{__dir__}/) + Msg.xmlfiles(@type))
        if newer
          verbose { "#{@type}/Cache File(#{newer}) is newer than cache" }
          verbose { "#{@type}/Cache cache=#{::File::Stat.new(@marfile).mtime}" }
          verbose { "#{@type}/Cache file=#{::File::Stat.new(newer).mtime}" }
          return false
        end
      end
      true
    end

    def cmp(ary)
      ary.each do|f|
        return f if ::File.file?(f) && test('>', f, @marfile)
      end
      false
    end

    def par2item(e, item)
      case e.name
      when 'par_num'
        attr = { type: 'num', list: e.text.split(',') }
        attr[:label] = e[:label] if e[:label]
        (item[:parameters] ||= []) << attr
      when 'par_str'
        attr = { type: 'str', list: e.text.split(',') }
        attr[:label] = e[:label] if e[:label]
        (item[:parameters] ||= []) << attr
      end
    end

    # For Command DB
    def init_command(dbc, dbi)
      @idx = {}
      @grps = {}
      @units = {}
      dbc.each do|e| # e.name should be group
        Msg.give_up('No group in dbc') unless e.name == 'group'
        gid = e.attr2item(@grps)
        arc_unit(e, gid)
      end
      dbi[:command] = { group: @grps, index: @idx }
      dbi[:command][:unit] = @units unless @units.empty?
    end

    def arc_unit(e, gid)
      return unless e
      e.each do|e0|
        case e0.name
        when 'unit'
          uid = e0.attr2item(@units)
          (@grps[gid][:units] ||= []) << uid
          e0.each do|e1|
            id = arc_command(e1, gid)
            @idx[id][:unit] = uid
            (@units[uid][:members] ||= []) << id
          end
        when 'item'
          arc_command(e0, gid)
        end
      end
    end

    def arc_command(e0, gid)
      id = e0.attr2item(@idx)
      (@grps[gid][:members] ||= []) << id
      id
    end
  end
end
