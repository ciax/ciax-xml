#!/usr/bin/ruby
require 'libdb'
require 'librepeat'

module CIAX
  ####### For Command DB #######
  class DbCmd < Db
    def initialize(type, proj = nil)
      super
      @rep = Repeat.new
    end

    # Take parameter and next line
    def par2item(doc, item)
      return unless /par_(num|str|reg)/ =~ doc.name
      @argc += 1
      atrb = { type: Regexp.last_match(1), list: doc.text.split(',') }
      atrb[:label] = doc[:label] if doc[:label]
      item.get(:parameters) { [] } << atrb
    end

    # Check parameter var for subst in db
    def validate_par(db)
      res = db.deep_search(format('\$[%d-9]', @argc + 1))
      return db if res.empty?
      cfg_err("Too much parameter variables [#{res.join('/')}] for #{@argc}")
    ensure
      @argc = 0
    end

    def init_command(dbi)
      cdb = dbi.get(:command) { Hashx.new }
      @idx = cdb.get(:index) { Hashx.new }
      @grps = cdb.get(:group) { Hashx.new }
      @units = cdb.get(:unit) { Hashx.new }
      cdb
    end

    # Adapt to both XML::Gnu, Hash
    def _add_group(doc)
      doc.each_value do |e|
        # e.name should be group
        Msg.give_up('No group in cdb') unless e.name == 'group'
        gid = e.attr2item(@grps)
        _add_member(e, gid)
      end
    end

    def _add_member(doc, gid)
      return unless doc
      doc.each do |e0|
        case e0.name
        when 'unit'
          _add_unit(e0, gid)
        when 'item'
          _add_item(e0, gid)
        end
      end
      self
    end

    def _add_unit(e0, gid)
      uid = e0.attr2item(@units)
      @grps[gid].get(:units) { [] } << uid
      e0.each do |e1|
        id, itm = _add_item(e1, gid)
        itm[:unit] = uid
        @units[uid].get(:members) { [] } << id
      end
    end

    def _add_item(doc, gid)
      id = doc.attr2item(@idx)
      @grps[gid].get(:members) { [] } << id
      [id, @idx[id]] # item is used by child
    end
  end
end
