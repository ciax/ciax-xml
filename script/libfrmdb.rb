#!/usr/bin/ruby
require 'librepeat'
require 'libdb'

module CIAX
  # Frame Layer
  module Frm
    # Frame DB
    class Db < Db
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
        enclose('INIT:Main Frame <-', '-> INIT:Main Frame') do
          frame = []
          domain.each { |e1| frame << yield(e1) }
          verbose { "InitMainFrame:#{frame}" }
          db[:main] = frame
        end
        domain.find('ccrange') do|e0|
          enclose('INIT:Ceck Code Frame <-', '-> INIT:Ceck Code Frame') do
            frame = []
            Repeat.new.each(e0) { |e1, r1| frame << yield(e1, r1) }
            verbose { "InitCCFrame:#{frame}" }
            db[:ccrange] = frame
          end
        end
        db
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
          Repeat.new.each(e0) do|e1, r1|
            par2item(e1, itm) && next
            e = _add_cmdfrm(e1, r1) || next
            itm.get(:body) { [] } << e
            verbose { "Body Frame [#{e.inspect}]" }
          end
          validate_par(itm)
        end
        [id, itm]
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
        dbi[:field] = fld = Hashx.new
        frm = init_frame(dom[:rspframe]) { |e| _add_rspfrm(e, fld) }
        idx = _add_response(dom[:response], fld)
        dbi[:frm_id] = dbi[:id]
        dbi[:response] = Hashx.new(index: idx, frame: frm)
        dbi
      end

      def _add_response(domain, fld)
        db = Hashx.new
        domain.each do|e0|
          id = e0.attr2item(db)
          itm = db[id]
          enclose("INIT:Body Frame [#{id}]<-", '-> INIT:Body Frame') do
            Repeat.new.each(e0) do|e1, _r1|
              e = _add_rspfrm(e1, fld) || next
              itm.get(:body) { [] } << e
            end
          end
        end
        db
      end

      def _add_rspfrm(e, field)
        # Avoid override duplicated id
        if (id = e[:assign]) && !field.key?(id)
          itm = field[id] = { label: e[:label] }
        end
        case e.name
        when 'field'
          atrb = e.to_h
          itm[:struct] = [] if itm
          verbose { "InitElement: #{atrb}" }
          atrb
        when 'array'
          atrb = e.to_h
          idx = atrb[:index] = []
          e.each { |e1| idx << e1.to_h }
          itm[:struct] = idx.map { |h| h[:size] } if itm
          verbose { "InitArray: #{atrb}" }
          atrb
        when 'ccrange', 'body', 'echo'
          e.name
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
