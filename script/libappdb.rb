#!/usr/bin/ruby
require 'libwatdb'

module CIAX
  # Application Layer
  module App
    # Application DB
    class Db < DbTree
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
        @rep.each(e0) do |e1|
          par2item(e1, itm) && next
          _add_frmcmd_(e1, itm)
        end
        validate_par(itm)
        [id, itm]
      end

      def _add_frmcmd_(e1, itm)
        return if e1.name != 'frmcmd'
        command = [e1[:name]]
        e1.each do |e2|
          command << _make_argv_(e2)
        end
        itm.get(:body) { [] } << command
      end

      def _make_argv_(e2)
        argv = e2.to_h
        argv[:val] = @rep.subst(e2.text)
        if /\$/ !~ argv[:val]
          fmt = argv.delete(:format)
          argv[:val] = fmt % expr(argv[:val]) if fmt
        end
        argv
      end

      # Status Db
      def init_status(adbs, dbi)
        sdb = { group: Hashx.new, index: Hashx.new, symtbl: [] }
        @rep.each(adbs) do |e|
          _grp_stat_(e, sdb)
        end
        dbi[:status] = adbs.to_h.update(sdb)
      end

      def _grp_stat_(e, sdb)
        case e.name
        when 'group'
          gid = e.attr2item(sdb[:group]) { |v| @rep.formatting(v) }
          _rec_stat_(e, sdb[:index], sdb[:group][gid])
        when 'symtbl'
          sdb[:symtbl] << e['ref']
        end
      end

      # recursive method
      def _rec_stat_(e, idx, grp)
        @rep.each(e) do |e0| # e0 can be 'binary', 'integer', 'float'..
          id = e0.attr2item(idx) { |v| @rep.formatting(v) }
          itm = idx[id]
          grp.get(:members) { [] } << id
          itm[:type] = e0.name
          itm[:fields] = []
          _add_fields_(e0, itm[:fields])
        end
      end

      def _add_fields_(e0, fields)
        @rep.each(e0) do |e1|
          st = {}
          st[:sign] = 'true' if e1.name == 'sign'
          _add_atrb_(e1, st)
          i = st.delete(:index)
          st[:ref] << ":#{i}" if i
          fields << st
        end
      end

      def _add_atrb_(e1, st)
        e1.to_h.each do |k, v|
          v = @rep.subst(v) if k.to_s =~ /bit|index/
          st[k] = v
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[id] (key) ..', options: 'r') do |opt, args|
        dbi = Db.new.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
