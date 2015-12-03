#!/usr/bin/ruby
# IDB CSV(CIAX-v1) to XML
#alias m2x
require 'json'

def mktag(tag, attr)
  printf('  ' * @indent + '<%s', tag)
  attr.each do|k, v|
    printf(' %s="%s"', k, v)
  end
end

def indent(tag, attr = {}, text = nil)
  mktag(tag, attr)
  if text
    printf(">%s</%s>\n", text, tag)
  else
    puts '/>'
  end
end

def topen(tag, attr = {})
  mktag(tag, attr)
  puts '>'
  @indent += 1
end

def tclose(tag)
  @indent -= 1
  printf('  ' * @indent + "</%s>\n", tag)
  nil
end

def enclose(tag, attr = {})
  topen(tag, attr)
  yield
  tclose(tag)
end

def mkattr(vals, *tags)
  attr = {}
  vals.each do|val|
    attr[tags.shift] = val
  end
  attr
end

def prt_cond(fld)
  fld.each do|ary|
    ope = ary.shift
    val = ary.shift
    attr = mkattr(ary, 'site', 'var', 'skip')
    attr[:form] = 'msg'
    indent(ope, attr, val)
  end
end

def prt_seq(ary)
  ary.each do|e|
    case e
    when Array
      if e[0].to_s == 'mcr'
        indent(e[0], name: e[1])
      else
        indent(e.shift, mkattr(e,'site', 'name', 'skip'))
      end
    else
      prt_wait(e)
    end
  end
end

def prt_wait(e)
  if e['sleep']
    indent(:wait, sleep: e['sleep'])
  else
    enclose(:wait, retry: e['retry']) do
      prt_cond(e['until'])
    end
  end
end

abort 'Usage: mdb2xml [mdb(json) file]' if STDIN.tty? && ARGV.size < 1

@mdb = JSON.load(gets(nil))
@mcap = @mdb.delete('caption_macro') || 'ciax'
@ucap = @mdb.delete('caption_unit') || {}
@gcap = @mdb.delete('caption_group') || {}
@indent = 0
@unit=nil
puts '<?xml version="1.0" encoding="utf-8"?>'
enclose(:mdb, xmlns: 'http://ciax.sum.naoj.org/ciax-xml/mdb') do
  label = "#{@mcap.upcase} Macro"
  enclose(:macro, id: @mcap, version: '1', label: label, port: '55555') do
    @mdb.each do|grp, mem|
      enclose(:group, id: grp) do
        mem.each do|id, db|
          if @unit != db['unit']
            tclose('unit') if @unit
            @unit = db['unit']
            topen('unit',id: @unit, label: @ucap[@unit]) if @unit
          end
          attr = { id: id }
          attr[:label] = db['label'] if db['label']
          enclose(:item, attr) do
            db.each do|key, ary|
              case key
              when 'goal'
                enclose(:goal) do
                  prt_cond(ary)
                end
              when 'check'
                enclose(:check) do
                  prt_cond(ary)
                end
              when 'seq'
                prt_seq(ary)
              when 'select'
                attr = { site: ary['site'], var: ary['var'], form: 'msg' }
                enclose(:select, attr) do
                  ary['option'].each do|val, mcr|
                    enclose(:option, val: val) do
                      indent(:mcr, name: mcr)
                    end
                  end
                end
              end
            end
          end
        end
        @unit=tclose('unit') if @unit
      end
    end
  end
end
