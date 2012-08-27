#!/usr/bin/env ruby
# 1.9 adds realpath to resolve symlinks; 1.8 doesn't
# have this method, so we add it so we get resolved symlinks
# and compatibility
unless File.respond_to? :realpath
  class File #:nodoc:
    def self.realpath path
      return realpath(File.readlink(path)) if symlink?(path)
      path
    end
  end
end
$: << File.expand_path(File.dirname(File.realpath(__FILE__)) + '/../lib')

require 'rubygems'
# require 'bundler/setup'
require 'gli'
require 'pp'
require 'logger'
require 'es'

include GLI

program_desc 'ES transformer - This tool should help you with transformation of old JSON files'

desc 'Parse load file'
command :parse do |c|
#     c.desc 'Link to file to parse'
#     c.default_value nil
#     c.flag [:l, :loadfile]
#     
#     c.desc 'Name of output file'
#     c.default_value nil
#     c.flag [:o, :output]
#     
#     c.desc 'Extract file name'
#     c.default_value nil
#     c.flag [:e, :extractfile]

    c.desc 'Input folder'
    c.default_value nil
    c.flag [:f, :inputfolder]

    c.desc 'Output folder'
    c.default_value nil
    c.flag [:o, :outputfolder]
    
    c.action do |global_options,options,args|
      inputfolder = options[:inputfolder]
      outputfolder = options[:outputfolder]
      fail "Directory #{inputfolder} cannot be found" unless File.directory?(inputfolder)
      #If output directory not exists, create it
      if !File.directory?(outputfolder) then
         Dir::mkdir(outputfolder)
      end 

       Dir.foreach(inputfolder) do |file|
         if (file=~ /load_.*.json/ ) then
           extractfile = file.sub("load","extract")
           if (File.exists?(inputfolder + extractfile)) then
             # Here we are loading load json script
             load_config_file = Es::Helpers.load_config(inputfolder + file) 
             l = Es::Load.parseOldFormat(load_config_file)
             # Saving file in new format
             File.open(outputfolder + file, 'w') do |f|
                f.write(JSON.pretty_generate(l.to_config_generator))
             end
             
             extract_config_file = Es::Helpers.load_config(inputfolder + extractfile)
             e = Es::Extract.parseOldFormat(extract_config_file[:readTask],l)
             e.map do |entity|
                File.open(outputfolder + extractfile, 'w') do |f|
                  f.write(JSON.pretty_generate(entity.to_extract_configuration))
                end
             end
           else 
             load_config_file = Es::Helpers.load_config(inputfolder + file) 
             l = Es::Load.parseOldFormat(load_config_file)
             # Saving file in new format
             File.open(outputfolder + file, 'w') do |f|
                f.write(JSON.pretty_generate(l.to_config_generator))
             end
           end
         end
       end
       puts "Done"

    end
end



on_error do |exception|
  pp exception.backtrace
  if exception.is_a?(SystemExit) && exception.status == 0
    false
  else
    true
  end
  
  # Error logic here
  # return false to skip default error handling
  # false
  # true
end

exit GLI.run(ARGV)
