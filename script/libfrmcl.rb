#!/usr/bin/ruby
require "libinsdb"
require "libclient"
require "libiofile"
require "libparam"

class FrmCl
 def initialize(fdb,host)
   @cli=Client.new(fdb['id'],fdb['port'].to_i-1000,host)
   @field=IoFile.new('field',fdb['id'],host)
   @par=Param.new(fdb[:cmdframe])
 end

 def upd(cmd)
   if @cli.upd(cmd).message
     @par.set(cmd)
   else
     @field.load
   end
   self
 end

 def to_s
   @cli.message||@field
 end
end
