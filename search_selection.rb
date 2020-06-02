# frozen_string_literal: true

require 'erb'
require 'json'
require 'shellwords'

# Extends File object.
class File
  # Remove single quote around file path from Alfred File Browser
  def self.strip_single_quote(filepath)
    /^'.*'$/.match?(filepath) ? filepath[1..-2] : filepath
  end

  def self.image?(filepath)
    # Limits by Google Image Search
    # The image must be in one of the following formats:
    # .jpg, .gif, .png, .bmp, .tif, or .webp.
    /^.*\.(jpe?g|gif|png|bmp|tif|webp)$/i.match?(filepath)
  end
end

def search_text(query)
  lines = query.split("\n").reject(&:empty?)
  lines.each do |line|
    system "open 'https://google.com/search?q=#{ERB::Util.url_encode(line)}'"
  end
end

def extract_urls(query)
  # Regex is from: https://gist.github.com/gruber/8891611
  url_regex = %r{(?i)\b((?:https?:(?:/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)/)(?:[^\s()<>{}\[\]]+|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’])|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)\b/?(?!@)))}
  # The result before is an embed array [[a], [b]].
  urls = query.scan(url_regex).flatten
  # Add https to raw domains.
  urls.map { |url| url =~ %r{^https?://} ? url : "https://#{url}" }
end

def open_urls(query)
  extract_urls(query).each { |url| system "open #{url}" }
end

def search_image(query)
  response = `curl -X POST -F smfile=@#{query} https://sm.ms/api/v2/upload`
  response = JSON.parse(response)
  image_url = response['images'] if response['code'] == 'image_repeated'
  image_url = response['data']['url'] if response['code'] == 'success'
  system "open https://images.google.com/searchbyimage?image_url=#{image_url}"
end

def push_notification(title, text)
  `osascript -e 'display notification "#{text}" with title "#{title}"'`
end

query = ARGV[0]
filepath = File.strip_single_quote(query)

if File.exist?(filepath)
  if File.image?(filepath)
    push_notification('Uploading image', 'Please wait for seconds')
    search_image(filepath.shellescape)
  else
    push_notification('Please select an image', '')
  end
elsif extract_urls(query).any?
  open_urls(query)
else
  search_text(query)
end
