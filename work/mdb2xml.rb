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

def enclose(tag, attr = {})
  mktag(tag, attr)
  puts '>'
  @indent += 1
  yield
  @indent -= 1
  printf('  ' * @indent + "</%s>\n", tag)
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

def prt_exe(ary)
  indent(:exec, mkattr(ary, 'site', 'name', 'skip'))
end

def prt_cfg(ary)
  indent(:cfg, mkattr(ary, 'site', 'name', 'skip'))
end

def prt_seq(seq)
  seq.each do|ary|
    if ary[0].to_s == 'mcr'
      indent(ary[0], name: ary[1])
    else
      prt_exe(ary)
    end
  end
end

abort 'Usage: mdb2xml [mdb(json) file]' if STDIN.tty? && ARGV.size < 1

proj = ENV['PROJ'] || 'moircs'

@mdb = JSON.load(gets(nil))
@indent = 0
puts '<?xml version="1.0" encoding="utf-8"?>'
enclose(:mdb, xmlns: 'http://ciax.sum.naoj.org/ciax-xml/mdb') do
  label = "#{proj.upcase} Macro"
  enclose(:macro, id: proj, version: '1', label: label, port: '55555') do
    @mdb.each do|grp, mem|
      enclose(:group, id: grp) do
        mem.each do|id, db|
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
              when 'exec'
                prt_exe(ary.first)
              when 'cfg'
                prt_cfg(ary.first)
              when 'seq'
                prt_seq(ary)
              when 'wait'
                if ary['sleep']
                  indent(:wait, sleep: ary['sleep'])
                else
                  enclose(:wait, retry: ary['retry']) do
                    prt_cond(ary['until'])
                  end
                end
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
      end
    end
  end
end
