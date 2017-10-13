#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libmansh'
# CIAX-XML Macro Shell
module CIAX
  ConfOpts.new('[proj]', options: 'eclhnr') do |cfg|
    Layer.new(cfg) do |cf|
      Mcr::Man.new(cf).run
    end.ext_shell.shell
  end
end
