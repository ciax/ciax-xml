#!/usr/bin/ruby
require 'libwatdb'

module CIAX
  module App
    class Db < Db
      include Wat::Db
      def initialize
        super('adb')
      end

      private

      def doc_to_db(doc)
        db = Dbi[doc[:attr]]
        # Domains
        init_command(doc, db)
        init_stat(doc, db)
        init_watch(doc, db)
        db['app_id'] = db['id']
        db
      end

      # Command Db
      def init_command(doc, db)
        adbc = doc[:domain]['command']
        idx = {}
        grps = {}
        units = {}
        adbc.each do|e|
          Msg.give_up('No group in adbc') unless e.name == 'group'
          gid = e.attr2item(grps)
          arc_unit(e, idx, grps[gid], units)
        end
        db[:command] = { group: grps, index: idx }
        db[:command][:unit] = units unless units.empty?
      end

      def arc_unit(e, idx, grp, units)
        e.each do|e0|
          case e0.name
          when 'unit'
            uid = e0.attr2item(units)
            e0.each do|e1|
              id = arc_command(e1, idx)
              (units[uid][:members] ||= []) << id
              idx[id]['unit'] = uid
              (grp[:members] ||= []) << id
            end
          when 'item'
            id = arc_command(e0, idx)
            (grp[:members] ||= []) << id
          end
        end
        idx
      end

      def arc_command(e0, idx)
        id = e0.attr2item(idx)
        item = idx[id]
        Repeat.new.each(e0) do|e1, rep|
          par2item(e1, item) && next
          case e1.name
          when 'frmcmd'
            command = [e1['name']]
            e1.each do|e2|
              argv = e2.to_h
              argv['val'] = rep.subst(e2.text)
              if /\$/ !~ argv['val']
                fmt = argv.delete('format')
                argv['val'] = fmt % eval(argv['val']) if fmt
              end
              command << argv
            end
            (item[:body] ||= []) << command
          end
        end
        id
      end

      # Status Db
      def init_stat(doc, db)
        adbs = doc[:domain]['status']
        grp = {}
        idx = Hashx.new
        Repeat.new.each(adbs) do|e, r|
          gid = e.attr2item(grp) { |_, v| r.formatting(v) }
          rec_stat(e, idx, grp[gid], r)
        end
        db[:status] = adbs.to_h.update(group: grp, index: idx)
      end

      def rec_stat(e, idx, grp, rep)
        rep.each(e) do|e0, r0|
          id = e0.attr2item(idx) { |_, v| r0.formatting(v) }
          item = idx[id]
          (grp[:members] ||= []) << id
          item['type'] = e0.name
          item[:fields] = []
          r0.each(e0) do|e1, r1|
            st = {}
            st['sign'] = 'true' if e1.name == 'sign'
            e1.to_h.each do|k, v|
              case k
              when 'bit', 'index'
                st[k] = r1.subst(v)
              else
                st[k] = v
              end
            end
            i = st.delete('index')
            st['ref'] << ":#{i}" if i
            e1.each do|e2|
              (st[:conv] ||= {})[e2.text] = e2['msg']
            end
            item[:fields] << st
          end
        end
        idx
      end
    end

    if __FILE__ == $PROGRAM_NAME
      begin
        db = Db.new.get(ARGV.shift)
      rescue InvalidID
        Msg.usage('[id] (key) ..')
      end
      puts db.path(ARGV)
    end
  end
end
