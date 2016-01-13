#!/usr/bin/ruby
require 'libwatdb'

module CIAX
  # Application Layer
  module App
    # Application DB
    class Db < Db
      include Wat::Db
      def initialize
        super('adb')
      end

      private

      def doc_to_db(doc)
        dbi = Dbi.new(doc[:attr])
        # Domains
        dom = doc[:domain]
        init_command(dom[:command], dbi)
        init_stat(dom[:status], dbi)
        init_watch(dom, dbi)
        dbi[:app_id] = dbi[:id]
        dbi
      end

      def _add_item(e0, gid)
        id, itm = super
        Repeat.new.each(e0) do|e1, rep|
          par2item(e1, itm) && next
          case e1.name
          when 'frmcmd'
            command = [e1[:name]]
            e1.each do|e2|
              argv = e2.to_h
              argv[:val] = rep.subst(e2.text)
              if /\$/ !~ argv[:val]
                fmt = argv.delete(:format)
                argv[:val] = fmt % expr(argv[:val]) if fmt
              end
              command << argv
            end
            (itm[:body] ||= []) << command
          end
        end
        validate_par(itm)
        [id, itm]
      end

      # Status Db
      def init_stat(adbs, dbi)
        grp = {}
        idx = {}
        Repeat.new.each(adbs) do|e, r|
          gid = e.attr2item(grp) { |_, v| r.formatting(v) }
          rec_stat(e, idx, grp[gid], r)
        end
        dbi[:status] = adbs.to_h.update(group: grp, index: idx)
      end

      # recursive method
      def rec_stat(e, idx, grp, rep)
        rep.each(e) do|e0, r0|
          id = e0.attr2item(idx) { |_, v| r0.formatting(v) }
          itm = idx[id]
          (grp[:members] ||= []) << id
          itm[:type] = e0.name
          itm[:fields] = []
          r0.each(e0) do|e1, r1|
            st = {}
            st[:sign] = 'true' if e1.name == 'sign'
            e1.to_h.each do|k, v|
              case k
              when :bit, :index
                st[k] = r1.subst(v)
              else
                st[k] = v
              end
            end
            i = st.delete(:index)
            st[:ref] << ":#{i}" if i
            e1.each do|e2|
              (st[:conv] ||= {})[e2.text] = e2[:msg]
            end
            itm[:fields] << st
          end
        end
        idx
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('r')
      begin
        dbi = Db.new.get(ARGV.shift)
      rescue InvalidID
        OPT.usage('[id] (key) ..')
      end
      puts OPT[:r] ? dbi.to_v : dbi.path(ARGV)
    end
  end
end
