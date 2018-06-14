#!/usr/bin/env ruby

require 'worldcat/discovery'
# WS Key String
key = '5cNC1Q8tS6IzlkyiLafg4xveLBdoX1hkXD5QAEBqfxclX6qXqHxlJIkmsbPsss4sgKH8yyzytye25loO'
 
# Secret
secret = 'DHLWPyINf+50hnePJGgqHFUm6ZsG0sSI'
 
# Set SSL version to TLSv1_2. Otherwise SSLv3 is used as default and results in handshake error
# Error will be triggered at https://github.com/OCLC-Developer-Network/oclc-auth-ruby/blob/master/lib/oclc/auth/access_token.rb#L58
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version] = 'TLSv1_2'
 
# Params to pass on to Auth server
authenticating_institution_id = 1284
context_institution_id = 1284
scope = 'WorldCatDiscoveryAPI'
 
# Create WSKey object
wskey = OCLC::Auth::WSKey.new(key, secret, :services => [scope])
 
WorldCat::Discovery.configure(wskey, authenticating_institution_id, context_institution_id)
 
params = Hash.new
params[:q] = 'programming ruby'
params[:facetFields] = ['itemType:10', 'inLanguage:10']
params[:startNum] = 0
results = WorldCat::Discovery::Bib.search(params)


puts results.first.methods
puts '#########'
puts '#########'  
puts '#########'
puts '#########'
puts '#########'
puts '#########'
puts results.first.subject.methods

results.bibs.each do |bib|
  puts bib.name
  puts bib.oclc_number
  puts bib.subject.value
  puts bib.author&.name
  puts bib.date_published
  puts '--------------------'
end

puts results.total_results.class

#results.bibs.map {|bib| str = bib.name; str += " (#{bib.date_published})"; puts bib.methods if bib.date_published; str}
