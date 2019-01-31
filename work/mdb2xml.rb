#!/usr/bin/env ruby
# IDB CSV(CIAX-v1) to XML
# alias m2x
require 'json'
require 'libxmlfmt'
# CIAX-XML
module CIAX
  VERSION = '2'.freeze
  # Config File converter
  class Mdb2Xml < Xml::Format
    OPETBL = { '=~' => 'match', '!=' => 'not' }.freeze
    OPETBL.update('==' => 'equal', '!~' => 'unmatch')
    def initialize(mdb)
      super()
      @mdb = mdb
      @unit = @mdb.delete(:unit) || {}
      @index = []
      push(Xml::HEADER)
      doc = enclose(:mdb, xmlns: 'http://ciax.sum.naoj.org/ciax-xml/mdb')
      tag_macro(doc)
    end

    def tag_macro(doc)
      mcap = @mdb.delete(:caption_macro) || 'ciax'
      label = "#{mcap.upcase} Macro"
      mat = Hashx.new(id: mcap, version: VERSION, label: label, port: '55555')
      mdoc = doc.enclose(:macro, mat)
      tag_groups(@mdb.delete(:group), mdoc)
    end

    def tag_groups(db, doc)
      return unless db
      db.each do |gid, gat|
        gdoc = doc.enclose(:group, Hashx.new(gat).attributes(gid))
        tag_units(gat, gdoc)
        tag_items(gat, gdoc)
      end
    end

    def tag_units(db, doc)
      return unless db[:units]
      db[:units].each do |uid|
        uat = @unit[uid.to_sym]
        udoc = doc.enclose(:unit, Hashx.new(uat).attributes(uid))
        tag_items(uat, udoc)
      end
    end

    def tag_items(db, doc)
      return unless db[:member]
      db[:member].each do |iid|
        next if @index.include?(iid)
        iat = @mdb[:index][iid.to_sym] || next
        @index << iid
        idoc = doc.enclose(:item, Hashx.new(iat).attributes(iid))
        tag_elements(iat, idoc)
      end
    end

    def tag_elements(db, doc)
      db.each do |key, ary|
        case key
        when :goal, :check
          tag_check(key, doc, ary)
        when :seq
          tag_seq(doc, ary)
        when :select
          tag_select(doc, ary)
        end
      end
    end

    def tag_check(key, doc, ary)
      sd = doc.enclose(key)
      ary.each do |cond|
        list_cond(sd, cond)
      end
    end

    def tag_seq(doc, ary)
      ary.each do |e|
        case e
        when Array
          tag_action(e, doc)
        else
          tag_wait(doc, e)
          tag_seq(doc, e[:post]) if e[:post]
        end
      end
    end

    def tag_action(e, doc)
      # Don't use e.shift which will affect following process
      args = Arrayx.new(e)
      cmd = args.shift
      if cmd.to_s == 'mcr'
        doc.element(cmd, nil, args.a2h(:name))
      elsif cmd.to_s == 'system'
        doc.element(cmd, args.shift)
      else
        doc.element(cmd, nil, args.a2h(:site, :name, :skip))
      end
    end

    def tag_wait(doc, e)
      ex = Hashx.new(e)
      if e[:sleep]
        doc.element(:sleep, ex[:sleep])
      else
        sd = doc.enclose(:wait, ex.pick([:retry, :label]))
        e[:until].each do |cond|
          list_cond(sd, cond, 'data')
        end
      end
    end

    def list_cond(doc, cond, form = 'msg')
      atrb = Arrayx.new(cond).a2h(:site, :var, :ope, :cri, :skip)
      atrb[:form] = form
      ope = OPETBL[atrb.delete(:ope)]
      cri = atrb.delete(:cri)
      doc.element(ope, cri, atrb)
    end

    def tag_select(doc, elem)
      sat = Hashx.new(elem).attributes
      sat[:form] = 'msg'
      sd = doc.enclose(:select, sat)
      elem[:option].each do |val, name|
        sd.enclose(:option, val: val).element(:mcr, nil, name: name)
      end
    end
  end

  abort 'Usage: mdb2xml [mdb(json) file]' if STDIN.tty? && ARGV.empty?

  mdb = JSON.parse(gets(nil), symbolize_names: true)
  doc = Mdb2Xml.new(mdb)
  puts doc
end
