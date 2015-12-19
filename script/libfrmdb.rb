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
        dbi = Dbi.new(doc[:attr])
        dbi[:stream] = doc[:stream]
        dom = doc[:domain]
        init_command(dom, dbi)
        init_stat(dom, dbi)
        dbi
      end

      # Command section
      def init_command(dom, dbi)
        frm = init_frame(dom[:cmdframe]) { |e, r| init_cmd(e, r) }
        idx = init_index(dom[:command]) { |e, r| init_cmd(e, r) }
        grp = { main: { caption: 'Device Commands', members: idx.keys } }
        dbi[:command] = { group: grp, index: idx, frame: frm }
        dbi
      end

      # Status section
      def init_stat(dom, dbi)
        dbi[:field] = fld = {}
        frm = init_frame(dom[:rspframe]) { |e| init_rsp(e, fld) }
        idx = init_index(dom[:response]) { |e| init_rsp(e, fld) }
        dbi[:frm_id] = dbi[:id]
        dbi[:response] = { index: idx, frame: frm }
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

      def init_index(domain)
        db = {}
        domain.each do|e0|
          id = e0.attr2item(db)
          item = db[id]
          enclose("INIT:Body Frame [#{id}]<-", '-> INIT:Body Frame') do
            Repeat.new.each(e0) do|e1, r1|
              par2item(e1, item) && next
              e = yield(e1, r1) || next
              (item[:body] ||= []) << e
            end
          end
        end
        db
      end

      def init_cmd(e, rep = nil)
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

      def init_rsp(e, field)
        # Avoid override duplicated id
        if (id = e[:assign]) && !field.key?(id)
          item = field[id] = { label: e[:label] }
        end
        case e.name
        when 'field'
          atrb = e.to_h
          item[:struct] = [] if item
          verbose { "InitElement: #{atrb}" }
          atrb
        when 'array'
          atrb = e.to_h
          idx = atrb[:index] = []
          e.each { |e1| idx << e1.to_h }
          item[:struct] = idx.map { |h| h[:size] } if item
          verbose { "InitArray: #{atrb}" }
          atrb
        when 'ccrange', 'body', 'echo'
          e.name
        end
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
