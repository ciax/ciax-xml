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
        adbc.each{|e|
          Msg.abort('No group in adbc') unless e.name == 'group'
          gid = e.attr2item(grps)
          arc_unit(e, idx, grps[gid], units)
        }
        db[:command] = { :group => grps, :index => idx }
        db[:command][:unit] = units unless units.empty?
      end

      def arc_unit(e, idx, grp, units)
        e.each{|e0|
          case e0.name
          when 'unit'
            uid = e0.attr2item(units)
            e0.each{|e1|
              id = arc_command(e1, idx)
              (units[uid][:members] ||= []) << id
              idx[id]['unit'] = uid
              (grp[:members] ||= []) << id
            }
          when 'item'
            id = arc_command(e0, idx)
            (grp[:members] ||= []) << id
          end
        }
        idx
      end

      def arc_command(e0, idx)
        id = e0.attr2item(idx)
        item = idx[id]
        Repeat.new.each(e0){|e1, rep|
          par2item(e1, item) && next
          case e1.name
          when 'frmcmd'
            command = [e1['name']]
            e1.each{|e2|
              argv = e2.to_h
              argv['val'] = rep.subst(e2.text)
              if /\$/ !~ argv['val']
                fmt = argv.delete('format')
                argv['val'] = fmt % eval(argv['val']) if fmt
              end
              command << argv
            }
            (item[:body] ||= []) << command
          end
        }
        id
      end

      # Status Db
      def init_stat(doc, db)
        adbs = doc[:domain]['status']
        grp = {}
        idx = Hashx.new
        Repeat.new.each(adbs){|e, r|
          gid = e.attr2item(grp) { |_, v| r.format(v) }
          rec_stat(e, idx, grp[gid], r)
        }
        db[:status] = adbs.to_h.update(:group => grp, :index => idx)
      end

      def rec_stat(e, idx, grp, rep)
        rep.each(e){|e0, r0|
          id = e0.attr2item(idx) { |_, v| r0.format(v) }
          item = idx[id]
          (grp[:members] ||= []) << id
          item['type'] = e0.name
          item[:fields] = []
          r0.each(e0){|e1, r1|
            st = {}
            st['sign'] = 'true' if e1.name == 'sign'
            e1.to_h.each{|k, v|
              case k
              when 'bit', 'index'
                st[k] = r1.subst(v)
              else
                st[k] = v
              end
            }
            i = st.delete('index')
            st['ref'] << ":#{i}" if i
            e1.each{|e2|
              (st[:conv] ||= {})[e2.text] = e2['msg']
            }
            item[:fields] << st
          }
        }
        idx
      end
    end

    if __FILE__ == $0
      begin
        db = Db.new.get(ARGV.shift)
      rescue InvalidID
        Msg.usage('[id] (key) ..')
      end
      puts db.path(ARGV)
    end
  end
end
