#!/usr/bin/env ruby
require 'libdb'
require 'libxmlrepeat'

module CIAX
  module Dbx
    ####### For Command DB #######
    class Tree < Index
      def initialize(type)
        super
        @rep = Xml::Repeat.new
      end

      private

      # Take parameter and next line
      def _par2form(doc, form)
        return unless /par_(num|str|reg)/ =~ doc.name
        @argc += 1
        atrb = { type: Regexp.last_match(1), list: doc.text.split(',') }
        atrb[:label] = doc[:label] if doc[:label]
        form.get(:parameters) { [] } << atrb
      end

      # Check parameter var for subst in db
      def _validate_par(db)
        res = db.deep_search(format('\$[%d-9]', @argc + 1))
        return db if res.empty?
        rl = res.join('/')
        cfg_err("Can't replace Parameter (No <par_num>?) [#{rl}] for #{@argc}")
      ensure
        @argc = 0
      end

      def _init_command_db(dbi, doc = nil)
        @cdb = dbi.get(:command) { Hashx.new }
        @idx = @cdb.get(:index) { Hashx.new }
        @grps = @cdb.get(:group) { Hashx.new }
        @units = @cdb.get(:unit) { Hashx.new }
        doc.each_value { |e| _add_group(e) } if doc
      end

      # Adapt to both XML::Gnu, Hash
      def _add_group(e)
        # e.name should be group
        Msg.give_up('No group in cdb') unless e.name == 'group'
        gid = e.attr2item(@grps)
        ___add_member(e, gid)
      end

      def ___add_member(doc, gid)
        return unless doc
        doc.each do |e0|
          case e0.name
          when 'unit'
            ___add_unit(e0, gid)
          when 'item'
            _add_form(e0, gid)
          end
        end
        self
      end

      def ___add_unit(e0, gid)
        uid = e0.attr2item(@units)
        @grps[gid].get(:units) { [] } << uid
        e0.each do |e1|
          id = _add_form(e1, gid).first
          @units[uid].get(:members) { [] } << id
        end
      end

      def _add_form(doc, gid)
        id = doc.attr2item(@idx)
        @grps[gid].get(:members) { [] } << id
        [id, @idx[id]] # item is used by child
      end

      def _get_h(e)
        yield(h = e.to_h)
        h
      end
    end
  end
end
