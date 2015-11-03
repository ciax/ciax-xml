#!/usr/bin/ruby
require 'librepeat'
require 'libdb'

module CIAX
  module Mcr
    class Db < Db
      def initialize
        super('mdb')
      end

      def get
        doc = Hashx.new
        ary = @displist.keys
        doc = super(ary.shift)
        ary.inject(doc){|doc,id| doc.deep_update(super(id)) }
      end

      private

      def doc_to_db(doc)
        hash = Dbi[doc[:attr]]
        @id=hash['id']
        hash[:command] = init_command(doc[:top])
        hash
      end

      def init_command(mdbc)
        idx = {}
        grp = {}
        mdbc.each do|e|
          Msg.give_up('No group in mdbc') unless e.name == 'group'
          gid = e.attr2item(grp)
          arc_command(e, idx, grp[gid])
        end
        { group: grp, index: idx }
      end

      def arc_command(e, idx, grp)
        e.each do|e0|
          id = e0.attr2item(idx)
          verbose { "MACRO:[#{id}]" }
          item = idx[id]
          (grp[:members] ||= []) << id
          body = (item[:body] ||= [])
          final = {}
          e0.each do|e1|
            attr = e1.to_h
            par2item(e1, item) && next
            attr['type'] = e1.name
            case e1.name
            when 'mesg'
              body << attr
            when 'check', 'wait'
              body << make_condition(e1, attr)
            when 'goal'
              body << make_condition(e1, attr)
              final.update(attr.extend(Enumx).deep_copy)['type'] = 'check'
            when 'exec'
              attr['args'] = getcmd(e1)
              attr.delete('name')
              body << attr
              verbose { "COMMAND:[#{e1['name']}]" }
            when 'mcr'
              attr['args'] = getcmd(e1)
              attr.delete('name')
              body << attr
            when 'select'
              attr['select'] = get_option(e1)
              attr.delete('name')
              body << attr
            end
          end
          body << final unless final.empty?
        end
        idx
      end

      def make_condition(e1, attr)
        e1.each do|e2|
          hash = e2.to_h
          hash['cmp'] = e2.name
          (attr['cond'] ||= []) << hash
        end
        attr
      end

      def getcmd(e1)
        args = [e1['name']]
        e1.each do|e2|
          args << e2.text
        end
        args
      end

      def get_option(e1)
        options = {}
        e1.each do|e2|
          e2.each do|e3|
            options[e2['val'] || '*'] = getcmd(e3)
          end
        end
        options
      end
    end

    if __FILE__ == $PROGRAM_NAME
      begin
        mdb = Db.new.get #(PROJ || ARGV.shift)
      rescue InvalidID
        Msg.usage '[id] (key) ..'
      end
      puts mdb.path(ARGV)
    end
  end
end
