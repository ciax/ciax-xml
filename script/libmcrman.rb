#!/usr/bin/ruby
require "libmsg"
require "libmcrdb"
require "libint"
require "libmcrsub"
require "libmcrprt"

module Mcr
  class Man < Int::Shell
    attr_reader :prompt
    # @index=0: macro mode; @index > 0 sub macro mode(accepts y or n)
    def initialize(id)
      cobj=Command.new(Db.new(id)[:macro])
      super(cobj)
      flg=['test','sim','exe'][ENV['ACT'].to_i]
      @id="#{id}(#{flg})"
      @prompt="#@id[]>"
      @index=0
      @mcr=Mcr::Sub.new(@cobj,1) #.extend(Mcr::Prt)
      cl={"[0-9]"=>"Switch Mode","threads"=>"Thread list"}
      cl["list"] = "list mcr contents"
      cl["break"] = "[cmd|mcr] set break point"
      cl["step"] = "step in execution"
      cl["run"] = "run to break point"
      cl["continue"] = "continue execution"
      cl["print"] = "[dev:stat] print variable"
      cl["set"] = "[dev:stat=val] set variable"
      @cmdlist.add_group('int',"Internal Command",cl)
    end

    def exe(cmd)
      case cmd[0]
      when nil
      when 'threads'
        list=@mcr.map{|t| t[:cid]+'('+t[:stat]+')' }
        raise UserError,"#{list}"
      when /^[0-9]+$/
        i=cmd[0].to_i
        Msg.err("No Thread") if @mcr.size < i || i < 0
        @index=i
      when 'list'
        puts Msg.view_struct(@cobj)
      when /^\./
        @index=0
      else
        if @index > 0
          query(cmd[0])
        elsif Thread.list.size > 1
          Msg.err("  Another mcr is still running")
        else
          @mcr.clear.macro(cmd)
          Thread.pass
          @index=1
        end
      end
      upd_prompt
      ''
    end

    def to_s
      return '' unless current
      current[:obj].to_s
    end

    def current #current thread
      @mcr[@index-1] if @index > 0
    end

    private
    def query(str)
      case str
      when nil
      when /^y/i
        current.run if alive?
      when /^[s|n]/i
        current.raise(Broken) if alive?
      else
        raise SelectCMD,"Can't accept [#{str}]"
      end
    end

    def upd_prompt
      size=@mcr.size
      if @index > 0
        str=Msg.color(current[:cid],5)
        str << "[#@index/#{size}](#{current[:stat]})>"
        case current[:stat]
        when /wait/
          str << Msg.color("Proceed?(y/n)",9)
        when /run/
          str << Msg.color("('s' for stop)",9)
        end
        @prompt.replace(str)
      else
        flg=@mcr.map{|t|
          case t[:stat]
          when /wait/
            '?'
          when /run/
            '&'
          when /error/
            '!'
          else
            '.'
          end
        }.join('')
        @prompt.replace("#@id[#{flg}]>")
      end
    end

    def alive?
      @index > 0 && current.alive?
    end
  end
end
