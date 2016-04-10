#!/usr/bin/ruby
require 'librepeat'
require 'libdbcmd'

module CIAX
  # Frame Layer
  module Frm
    # Frame DB
    class Db < DbCmd
      def initialize
        super('fdb')
      end

      private

      def doc_to_db(doc)
        dbi = super
        dbi[:stream] = doc[:stream] || Hashx.new
        init_command(doc, dbi)
        init_response(doc, dbi)
        dbi
      end

      def init_frame(domain)
        db = domain.to_h
        _add_main(domain, db) { |e1| yield(e1) }
        _add_cc(domain, db) { |e1, r1| yield(e1, r1) }
        db
      end

      def _add_main(domain, db)
        enclose('INIT:Main Frame <-', '-> INIT:Main Frame') do
          frame = []
          domain.each { |e1| frame << yield(e1) }
          verbose { "InitMainFrame:#{frame}" }
          db[:main] = frame
        end
      end

      def _add_cc(domain, db)
        domain.find('ccrange') do|e0|
          enclose('INIT:Ceck Code Frame <-', '-> INIT:Ceck Code Frame') do
            frame = []
            Repeat.new.each(e0) { |e1, r1| frame << yield(e1, r1) }
            verbose { "InitCCFrame:#{frame}" }
            db[:ccrange] = frame
          end
        end
      end

      # Command section
      def init_command(dom, dbi)
        cdb = super(dbi)
        _add_group(dom[:command])
        cdb[:frame] = init_frame(dom[:cmdframe]) { |e, r| _add_cmdfrm(e, r) }
        cdb
      end

      def _add_item(e0, gid)
        id, itm = super
        enclose("INIT:Body Frame [#{id}]<-", '-> INIT:Body Frame') do
          _rep_item(e0, itm)
          validate_par(itm)
        end
        [id, itm]
      end

      def _rep_item(e0, itm)
        Repeat.new.each(e0) do|e1, r1|
          par2item(e1, itm) && next
          e = _add_cmdfrm(e1, r1) || next
          itm.get(:body) { [] } << e
          verbose { "Body Frame [#{e.inspect}]" }
        end
      end

      def _add_cmdfrm(e, rep = nil)
        case e.name
        when 'char', 'string'
          atrb = e.to_h
          atrb[:val] = rep.subst(atrb[:val]) if rep
          verbose { "Data:[#{atrb}]" }
          atrb
        else
          e.name
        end
      end

      # Status section
      def init_response(dom, dbi)
        fld = dbi[:field] = Hashx.new
        frm = init_frame(dom[:rspframe]) { |e| _add_rspfrm(e, fld) }
        dbi[:response] = Hashx.new(index: idx = Hashx.new, frame: frm)
        dom[:response].each { |e0| _add_fld(e0, fld, idx) }
        dbi[:frm_id] = dbi[:id]
        dbi
      end

      def _add_fld(e0, fld, db)
        id = e0.attr2item(db)
        enclose("INIT:Body Frame [#{id}]<-", '-> INIT:Body Frame') do
          itm = db[id]
          Repeat.new.each(e0) do|e1, _r1|
            e = _add_rspfrm(e1, fld) || next
            itm.get(:body) { [] } << e
          end
        end
      end

      def _add_rspfrm(e, field)
        # Avoid override duplicated id
        if (id = e[:assign]) && !field.key?(id)
          itm = field[id] = { label: e[:label] }
        end
        _init_elem(e, itm)
      end

      def _init_elem(e, itm)
        case e.name
        when 'field'
          _init_field(e, itm)
        when 'array'
          _init_ary(e, itm)
        when 'ccrange', 'body', 'echo'
          e.name
        end
      end

      def _init_field(e, itm)
        atrb = e.to_h
        itm[:struct] = [] if itm
        verbose { "InitField: #{atrb}" }
        atrb
      end

      def _init_ary(e, itm)
        atrb = e.to_h
        idx = atrb[:index] = []
        e.each { |e1| idx << e1.to_h }
        itm[:struct] = idx.map { |h| h[:size] } if itm
        verbose { "InitArray: #{atrb}" }
        atrb
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
