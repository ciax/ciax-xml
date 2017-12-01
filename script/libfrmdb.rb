#!/usr/bin/ruby
require 'libdbtree'

module CIAX
  # Frame Layer
  module Frm
    # Frame DB
    class Db < DbTree
      def initialize
        super('fdb')
      end

      private

      def _doc_to_db(doc)
        dbi = super
        dbi[:stream] = doc[:stream] || Hashx.new
        _init_command_db(dbi, doc)
        ___init_response(doc, dbi)
        dbi
      end

      # Command section
      def _init_command_db(dbi, doc)
        cdb = super(dbi, doc[:command])
        cdb[:frame] = __init_frame(doc[:cmdframe]) { |e| __add_cmdfrm(e) }
        cdb
      end

      def _add_item(e0, gid)
        id, itm = super
        # enclose("INIT:Body Frame [#{id}]<-", '-> INIT:Body Frame') do
        ___rep_item(e0, itm)
        _validate_par(itm)
        # end
        [id, itm]
      end

      def ___rep_item(e0, itm)
        @rep.each(e0) do |e1|
          _par2item(e1, itm) && next
          e = __add_cmdfrm(e1) || next
          itm.get(:body) { [] } << e
          verbose { "Body Frame [#{e.inspect}]" }
        end
      end

      def __add_cmdfrm(e)
        return e.name unless %w(char string).include?(e.name)
        _get_h(e) do |atrb|
          atrb[:val] = @rep.subst(atrb[:val])
          verbose { "Data:[#{atrb}]" }
        end
      end

      # Status section
      def ___init_response(dom, dbi)
        fld = dbi[:field] = Hashx.new
        frm = __init_frame(dom[:rspframe]) { |e| __add_rspfrm(e, fld) }
        dbi[:response] = Hashx.new(index: idx = Hashx.new, frame: frm)
        dom[:response].each { |e0| ___add_fld(e0, fld, idx) }
        dbi[:frm_id] = dbi[:id]
        dbi
      end

      def ___add_fld(e0, fld, db)
        itm = db[e0.attr2item(db)]
        @rep.each(e0) do |e1|
          e = __add_rspfrm(e1, fld) || next
          itm.get(:body) { [] } << e
        end
      end

      def __add_rspfrm(e, field)
        # Avoid override duplicated id
        if (id = e[:assign]) && !field.key?(id)
          itm = field[id] = { label: e[:label] }
        end
        ___init_elem(e, itm)
      end

      def ___init_elem(e, itm)
        case e.name
        when 'field'
          ___init_field(e, itm)
        when 'array'
          ___init_ary(e, itm)
        when 'ccrange', 'body', 'echo'
          e.name
        end
      end

      def ___init_field(e, itm)
        _get_h(e) do |atrb|
          itm[:struct] = [] if itm
          verbose { "InitField: #{atrb}" }
        end
      end

      def ___init_ary(e, itm)
        _get_h(e) do |atrb|
          idx = atrb[:index] = []
          e.each { |e1| idx << e1.to_h }
          itm[:struct] = idx.map { |h| h[:size] } if itm
          verbose { "InitArray: #{atrb}" }
        end
      end

      # Common Frame section
      def __init_frame(domain)
        _get_h(domain) do |db|
          ___add_main(domain, db) { |e1| yield(e1) }
          ___add_cc(domain, db) { |e1| yield(e1) }
        end
      end

      def ___add_main(domain, db)
        # enclose('INIT:Main Frame <-', '-> INIT:Main Frame') do
        frm = db[:main] = []
        domain.each { |e1| frm << yield(e1) }
        verbose { "InitMainFrame:#{frm}" }
        # end
      end

      def ___add_cc(domain, db)
        domain.find('ccrange') do |e0|
          # enclose('INIT:Ceck Code Frame <-', '-> INIT:Ceck Code Frame') do
          frm = db[:ccrange] = []
          @rep.each(e0) { |e1| frm << yield(e1) }
          verbose { "InitCCFrame:#{frm}" }
          # end
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
