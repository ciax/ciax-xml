#!/usr/bin/env ruby
require 'libwatdb'

module CIAX
  # Application Layer
  module App
    # Application DB
    class Db < Dbx::Tree
      include Wat::Db
      def initialize
        super('adb')
      end

      private

      def _doc_to_db(doc)
        dbi = super
        _init_command_db(dbi, doc[:command])
        ___init_status_db(doc[:status], dbi)
        _init_watch(doc, dbi)
        dbi[:app_id] = dbi[:id]
        dbi
      end

      def _add_form(e0, gid)
        id, itm = super
        @rep.each(e0) do |e1|
          _par2form(e1, itm) && next
          ___add_frmcmd(e1, itm)
        end
        _validate_par(itm)
        [id, itm]
      end

      def ___add_frmcmd(e1, itm)
        return if e1.name != 'frmcmd'
        command = [e1[:name]]
        e1.each do |e2|
          command << ___make_argv(e2)
        end
        itm.get(:body) { [] } << command
      end

      def ___make_argv(e2)
        argv = e2.to_h
        argv[:val] = @rep.subst(e2.text)
        if /\$/ !~ argv[:val]
          fmt = argv.delete(:format)
          argv[:val] = fmt % expr(argv[:val]) if fmt
        end
        argv
      end

      # Status Db
      def ___init_status_db(adbs, dbi)
        sdb = { group: Hashx.new, index: Hashx.new, symtbl: [] }
        @rep.each(adbs) do |e|
          ___grp_stat(e, sdb)
        end
        dbi[:status] = adbs.to_h.update(sdb)
      end

      def ___grp_stat(e, sdb)
        case e.name
        when 'group'
          gid = e.attr2item(sdb[:group]) { |v| @rep.formatting(v) }
          ___rec_stat(e, sdb[:index], sdb[:group][gid])
        when 'symtbl'
          sdb[:symtbl] << e['ref']
        end
      end

      # recursive method
      def ___rec_stat(e, idx, grp)
        @rep.each(e) do |e0| # e0 can be 'binary', 'integer', 'float'..
          id = e0.attr2item(idx) { |v| @rep.formatting(v) }
          itm = idx[id]
          grp.get(:members) { [] } << id
          itm[:type] = e0.name
          itm[:fields] = []
          ___add_fields(e0, itm[:fields])
        end
      end

      def ___add_fields(e0, fields)
        @rep.each(e0) do |e1|
          st = {}
          st[:sign] = 'true' if e1.name == 'sign'
          ___add_atrb(e1, st)
          i = st.delete(:index)
          st[:ref] << "@#{i}" if i
          fields << st
        end
      end

      def ___add_atrb(e1, st)
        e1.to_h.each do |k, v|
          v = @rep.subst(v) if k.to_s =~ /bit|index/
          st[k] = v
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[id] (key) ..', options: 'r') do |opt, args|
        dbi = Db.new.get(args.shift)
        puts opt[:r] ? dbi.to_v : dbi.path(args)
      end
    end
  end
end
