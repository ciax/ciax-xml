#!/usr/bin/ruby
# IDB CSV(CIAX-v1) to XML
#alias m2x
require 'json'
require 'libxmlfmt'
module CIAX
  class Mdb2Xml < Xml::Format
    OPETBL = { '=~' => 'match', '!=' => 'not', '==' => 'equal', '!~' => 'unmatch' }
    def initialize(mdb)
      super()
      @mdb = mdb
      @mcap = @mdb.delete(:caption_macro) || 'ciax'
      @group = @mdb.delete(:group) || {}
      @unit = @mdb.delete(:unit) || {}
      @index = []
      push(Xml::HEADER)
      mdb = enclose(:mdb, xmlns: 'http://ciax.sum.naoj.org/ciax-xml/mdb')
      mat = Hashx.new( id: @mcap, version: '1', port: '55555')
      mat[:label] = "#{@mcap.upcase} Macro"
      mcr = mdb.enclose(:macro, mat)
      @group.each_key do |gid|
        tag_group(mcr, gid)
      end
    end

    def prt_cond(doc, cond, form = 'msg')
      atrb = Arrayx.new(cond).a2h(:site, :var, :ope, :cri, :skip)
      atrb[:form] = form
      ope = OPETBL[atrb.delete(:ope)]
        cri = atrb.delete(:cri)
      doc.element(ope, cri, atrb)
    end

    def tag_wait(doc, e)
      ex = Hashx.new(e)
      if e[:sleep]
        doc.element(:wait, nil, ex.pick([:sleep, :label]))
      else
        sd = doc.enclose(:wait, ex.pick([:retry, :label]))
        e[:until].each do |cond|
          prt_cond(sd, cond, 'data')
        end
      end
    end

    def tag_seq(doc, ary)
      ary.each do|e|
        case e
        when Array
          # Don't use e.shift which will affect following process
          args = Arrayx.new(e)
          cmd = args.shift
          if cmd.to_s == 'mcr'
            doc.element(cmd, nil, args.a2h(:name))
          else
            doc.element(cmd, nil, args.a2h(:site, :name, :skip))
          end
        else
          tag_wait(doc, e)
          tag_seq(doc, e[:post]) if e[:post]
        end
      end
    end

    def tag_select(doc, elem)
      sat = Hashx.new(elem).attributes
      sat[:form] = 'msg'
      sd = doc.enclose(:select, sat)
      elem[:option].each do|val, name|
        sd.enclose(:option, val: val).element(:mcr, nil, name: name)
      end
    end

    def tag_item(doc, id)
      ie =@mdb[:index][id.to_sym]
      return unless ie
      return if @index.include?(id)
      @index << id
      itm = doc.enclose(:item, Hashx.new(ie).attributes(id))
      ie.each do|key, ary|
        case key
        when :goal,:check
          sd = itm.enclose(key)
          ary.each do |cond|
            prt_cond(sd, cond)
          end
        when :seq
          tag_seq(itm, ary)
        when :select
          tag_select(itm, ary)
        end
      end
    end

    def tag_unit(doc, uid)
      ue=@unit[uid.to_sym]
      ud = doc.enclose(:unit, Hashx.new(ue).attributes(uid))
      (ue[:member]||[]).each do |id|
        tag_item(ud, id)
      end
    end

    def tag_group(doc, gid)
      ge = @group[gid.to_sym]
      gd = doc.enclose(:group, Hashx.new(ge).attributes(gid))
      if ge[:units]
        ge[:units].each do |id|
          tag_unit(gd, id)
        end
      else
        ge[:member].each do |id|
          tag_item(gd, id)
        end
      end
    end
  end

  abort 'Usage: mdb2xml [mdb(json) file]' if STDIN.tty? && ARGV.size < 1

  mdb = JSON.parse(gets(nil), symbolize_names: true)
  doc = Mdb2Xml.new(mdb)
  puts doc
end
