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
        # Group DB
        hcmd=hash[:command]={}
        @cmdgrp=hcmd[:group]={}
        @stgrp=hash[:statgrp]={}
        # Domains
        dom=[]
        dom << domc=doc.domain('commands')
        hcmd[:index]=init_command(domc)
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
        hash={}
        adbc.each{|e|
          Msg.abort("No group in adbc") unless e.name == 'group'
          gid=e.attr2item(@cmdgrp)
          arc_command(e,hash,gid)
        }
        hash
      end

      def arc_command(e,hash,gid)
        e.each{|e0|
          id=e0.attr2item(hash)
          item=hash[id]
          label=item.delete('label')
          label=nil if /true|1/ === e0['hidden']
          (@cmdgrp[gid][:members]||={})[id]=label
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
        hash
      end

      # Status Db
      def init_stat(sdb)
        tmember={'time'=>'TIMESTAMP','elapse'=>'ELAPSED'}
        @stgrp['gtime']={'caption' =>'','column' => 2,:members =>tmember}
        rec_stat(sdb,Hashx.new,'gtime',Repeat.new)
      end

      def rec_stat(e,hash,gid,rep)
        rep.each(e){|e0,r0|
          case e0.name
          when 'group'
            gid=e0.attr2item(@stgrp){|k,v| r0.format(v)}
            rec_stat(e0,hash,gid,r0)
          else
            id=e0.attr2item(hash){|k,v| r0.format(v)}
            item=hash[id]
            (@stgrp[gid][:members]||={})[id]=item.delete('label')
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
          end
        }
        hash
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
