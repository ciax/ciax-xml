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
        dbi = super
        init_command(dbi)
        _add_group(doc[:command])
        init_status(doc[:status], dbi)
        init_watch(doc, dbi)
        dbi[:app_id] = dbi[:id]
        dbi
      end

      def _add_item(e0, gid)
        id, itm = super
        Repeat.new.each(e0) do|e1, rep|
          par2item(e1, itm) && next
          _add_frmcmd(e1, rep, itm)
        end
        validate_par(itm)
        [id, itm]
      end

      def _add_frmcmd(e1, rep, itm)
        return if e1.name != 'frmcmd'
        command = [e1[:name]]
        e1.each do|e2|
          command << _make_argv(e2, rep)
        end
        (itm[:body] ||= []) << command
      end

      def _make_argv(e2, rep)
        argv = e2.to_h
        argv[:val] = rep.subst(e2.text)
        if /\$/ !~ argv[:val]
          fmt = argv.delete(:format)
          argv[:val] = fmt % expr(argv[:val]) if fmt
        end
        argv
      end

      # Status Db
      def init_status(adbs, dbi)
        sdb = { group: Hashx.new, index: Hashx.new, symtbl: [] }
        Repeat.new.each(adbs) do|e, r|
          _grp_stat(e, r, sdb)
        end
        dbi[:status] = adbs.to_h.update(sdb)
      end

      def _grp_stat(e, r, sdb)
        case e.name
        when 'group'
          gid = e.attr2item(sdb[:group]) { |v| r.formatting(v) }
          _rec_stat(e, r, sdb[:index], sdb[:group][gid])
        when 'symtbl'
          sdb[:symtbl] << e['ref']
        end
      end

      # recursive method
      def _rec_stat(e, r, idx, grp)
        r.each(e) do|e0, r0| # e0 can be 'binary', 'integer', 'float'..
          id = e0.attr2item(idx) { |v| r0.formatting(v) }
          itm = idx[id]
          (grp[:members] ||= []) << id
          itm[:type] = e0.name
          itm[:fields] = []
          _add_fields(r0, e0, itm[:fields])
        end
      end

      def _add_fields(r0, e0, fields)
        r0.each(e0) do|e1, r1|
          st = {}
          st[:sign] = 'true' if e1.name == 'sign'
          _add_atrb(r1, e1, st)
          i = st.delete(:index)
          st[:ref] << ":#{i}" if i
          fields << st
        end
      end

      def _add_atrb(r1, e1, st)
        e1.to_h.each do|k, v|
          v = r1.subst(v) if k.to_s =~ /bit|index/
          st[k] = v
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id] (key) ..', 'r') do |opt, args|
        dbi = Db.new.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
