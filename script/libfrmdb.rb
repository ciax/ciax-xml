#!/usr/bin/env ruby
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
        _init_command_db(dbi, doc[:command])
        ___init_field(dbi, doc[:field])
        ___init_response(dbi, doc[:response])
        dbi
      end

      ######## Command section #######
      def _add_group(ec)
        if ec.name == 'frame'
          @cdb.get(:frame) do
            __init_frame(ec) { |e| __add_cmdfrm(e) }
          end
        else
          super
        end
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

      ######## Status section #######
      # Field section
      def ___init_field(dbi, dom)
        @fld = dbi[:field] = Hashx.new # template
        dom.each do |e|
          id = e.attr2item(@fld)
          ___init_ary(e, @fld[id]) if e.name == 'array'
        end
      end

      # pick child elements
      def ___init_ary(e, fval)
        return unless fval
        fval[:struct] = idx = []
        e.each { |e1| idx << e1.text }
        verbose { "InitArray: #{fval}" }
      end

      # Response section
      def ___init_response(dbi, dom)
        # Response DB (index)
        idx = Hashx.new
        @res = dbi[:response] = Hashx.new(index: idx)
        dom.each { |e0| ___add_fld(e0, idx) }
        dbi[:frm_id] = dbi[:id]
      end

      def ___add_fld(e0, db)
        if e0.name == 'frame'
          @res[:frame] = __init_frame(e0) { |e| __mk_rspfrm(e) }
        else
          itm = db[e0.attr2item(db)]
          @rep.each(e0) do |e1|
            itm.get(:body) { [] } << __mk_rspfrm(e1)
          end
        end
      end

      def __mk_rspfrm(e)
        db = { type: e.name }.update(e.to_h)
        e.each { |e1| (db[e1.name.to_sym] ||= []) << e1.text }
        db
      end

      ####### Common Frame section #######
      def __init_frame(domain)
        return unless domain
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
