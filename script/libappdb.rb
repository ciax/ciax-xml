#!/usr/bin/ruby
require "librepeat"
require "libdb"

module CIAX
  module App
    class Db < Db
      def initialize
        super('adb')
      end

      private
      def doc_to_db(doc)
        hash=Hash[doc]
        # Domains
        dom=[]
        dom << domc=doc.domain('commands')
        hash[:command]=init_command(domc)
        dom << doms=doc.domain('status')
        hash[:status]=init_stat(doms)
        if doc.domain?('watch')
          dom << domw=doc.domain('watch')
          hash[:watch]=init_watch(domw)
        end
        dom.each{|d| hash.update(d.to_h)}
        hash
      end

      # Command Db
      def init_command(adbc)
        idx={}
        grp=@cmdgrp={}
        adbc.each{|e|
          Msg.abort("No group in adbc") unless e.name == 'group'
          gid=e.attr2item(grp)
          arc_command(e,idx,grp[gid])
        }
        {:group => grp,:index => idx}
      end

      def arc_command(e,idx,grp)
        e.each{|e0|
          id=e0.attr2item(idx)
          item=idx[id]
          label=item.delete('label')
          label=nil if /true|1/ === e0['hidden']
          (grp[:members]||={})[id]=label
          Repeat.new.each(e0){|e1,rep|
            par2item(e1,item) && next
            case e1.name
            when 'frmcmd'
              command=[e1['name']]
              e1.each{|e2|
                argv=e2.to_h
                argv['val'] = rep.subst(e2.text)
                if /\$/ !~ argv['val'] && fmt=argv.delete('format')
                  argv['val']=fmt % eval(argv['val'])
                end
                command << argv
              }
              (item[:body]||=[]) << command
            end
          }
        }
        idx
      end

      # Status Db
      def init_stat(sdb)
        mbr={'time'=>'TIMESTAMP','elapse'=>'ELAPSED'}
        grp={'gtime'=>{'caption' =>'','column' => 2,:members =>mbr}}
        idx=Hashx.new
        Repeat.new.each(sdb){|e,r|
          gid=e.attr2item(grp){|k,v| r.format(v)}
          rec_stat(e,idx,grp[gid],r)
        }
        {:group => grp,:index => idx}
      end

      def rec_stat(e,idx,grp,rep)
        rep.each(e){|e0,r0|
          id=e0.attr2item(idx){|k,v| r0.format(v)}
          item=idx[id]
          (grp[:members]||={})[id]=item.delete('label')
          item['type'] = e0.name
          item[:fields] = []
          r0.each(e0){|e1,r1|
            st={}
            st['inv']='true' if e1.name == 'invert'
            e1.to_h.each{|k,v|
              case k
              when 'bit','index'
                st[k] = r1.subst(v)
              else
                st[k] = v
              end
            }
            if i=st.delete('index')
              st['ref'] << ":#{i}"
            end
            item[:fields] << st
          }
        }
        idx
      end

      # Watch Db
      #structure of exec=[cond1,2,...]; cond=[args1,2,..]; args1=['cmd','par1',..]
      def init_watch(wdb)
        return [] unless wdb
        hash={}
        [:label,:exec,:stat,:int,:block].each{|k| hash[k]={}}
        Repeat.new.each(wdb){|e0,r0|
          idx=r0.format(e0['id'])
          hash[:label][idx]=(e0['label'] ? r0.format(e0['label']) : nil)
          e0.each{ |e1|
            case name=e1.name.to_sym
            when :block,:int,:exec
              args=[e1['name']]
              e1.each{|e2|
                args << r0.subst(e2.text)
              }
              (hash[name][idx]||=[]) << args
            when :block_grp
              blk=(hash[:block][idx]||=[])
              @cmdgrp[e1['ref']][:members].each{|id| blk << [id]}
            else
              h=e1.to_h
              h.each_value{|v| v.replace(r0.format(v))}
              h['type']=e1.name
              (hash[:stat][idx]||=[]) << h
            end
          }
        }
        hash
      end
    end
  end

  if __FILE__ == $0
    begin
      db=App::Db.new.set(ARGV.shift)
    rescue InvalidID
      Msg.usage("[id] (key) ..")
    end
    puts db.path(ARGV)
    exit
  end
end
