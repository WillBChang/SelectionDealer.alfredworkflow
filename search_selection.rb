# frozen_string_literal: true

require 'uri'
require 'erb'

urls = URI.extract(ARGV[0])
lines = ARGV[0].split("\n").reject(&:empty?)[0..4]
if urls.empty?
  lines.each do |line|
    system "open 'https://google.com/search?q=#{ERB::Util.url_encode(line)}'"
  end
else
  urls.each { |url| system "open #{url}" }
end
