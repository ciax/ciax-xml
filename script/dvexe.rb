#!/usr/bin/ruby
require "libsitelist"
require "libhexexe"

module CIAX
  GetOpts.new("afxtelsch:")
  db={'x' => 'hex','f'=>'frm','a'=>'app','w'=>'wat'}
  layer=$opt.map{|k,v| db[k] if v}.compact.last
  begin
    puts Site::List.new(layer).exe(ARGV).output
  rescue InvalidID
    $opt.usage('(opt) [site] [cmd]')
  end
end
