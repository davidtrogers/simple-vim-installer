#!/bin/ruby

require 'rubygems'
require 'net/ftp'
# require 'ruby-debug'
require 'fileutils'

include FileUtils

puts '*** getting all patches'
rm_rf 'patches'
rm_rf 'vim73'
mkdir 'patches'
mkdir 'vim73'
cd 'patches'
Net::FTP.open('ftp.vim.org') do |ftp|
  ftp.login
  files = ftp.chdir('pub/vim/patches/7.3')
  files = ftp.list('*')
  files.each do |file|
    puts "getting #{file.split.last}" if file.split.last.scan(/7\.3\.\d{3}$/)[0]
    ftp.get(file.split.last) if file.split.last.scan(/7\.3\.\d{3}$/)[0]
  end
end
cd '../'

puts '*** finished getting patches'
Net::FTP.open('ftp.vim.org') do |ftp|
  ftp.login
  files = ftp.chdir('pub/vim/unix')
  files = ftp.list('')
  puts '*** getting the vim source'
  ftp.get('vim-7.3.tar.bz2')
end

puts '*** extracting the vim source'
system 'tar xvjf vim-7.3.tar.bz2 2>&1'

puts '*** removing downloaded tarball'
rm 'vim-7.3.tar.bz2'

puts '*** applying patches'
cd 'vim73'
files = Dir['../patches/7.3.*']
files.each do |file|
  system "patch -t -p0 < #{file} >&1 |tee >> patch.log"
end

puts '*** updating vim runtime files'
system 'rsync -avzcP --delete --exclude="/dos/" ftp.nluug.nl::Vim/runtime/ ./runtime/ 2>&1 |tee rsync.log'

#makefile = File.open('src/Makefile', 'r+')
# just want to include ruby for now
#makefile.each_line do |line|
#  puts makefile.write line.gsub('#','') if line =~ /--enable-rubyinterp$/ 
#end.close

system(<<-CONFIG)
./configure --with-features=huge  \
        --enable-rubyinterp       \
        --enable-pythoninterp     \
        --enable-perlinterp       \
        2>&1 |tee configure.log
CONFIG

system 'make 2>&1 |tee make.log'

puts <<-THEEND 

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        That's all for me.  Next check out the compiled version with:

                  vim73/src/vim --version 

        and you should see that all patches were applied. 
        Next copy vim, vimtutor, and any other binaries you want to 
        keep from this deeply moving experience to a directory in your 
        path, and have fun with some vanilla vim!
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
THEEND
