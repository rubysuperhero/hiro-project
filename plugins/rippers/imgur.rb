#!/usr/bin/env ruby

require 'mechanize'
require 'fileutils'
require 'open-uri'
require 'pp'

require 'pry'

class Imgur < BaseRipper
  register :imgur

  class << self
    def url_patterns
      [
        /imgur[.]com/i,
      ]
    end

    def matches?(url=`pbpaste`)
      return true if url_patterns.any?{|re| url[re] }
      false
    end

    def rip(args=ARGV.clone)
      new(args).tap(&:rip)
    end
  end

  attr_accessor :args
  def initialize(args=ARGV.clone)
    @args = args

    parse_options

    cd_to album_path
  end

  def url
    @url ||= args[0] || `pbpaste`
  end

  def rip
    puts "Downloading Album: '%s'..." % folder
    ap images: images
    images.map do |a|
      filename = File.basename(a)
      if File.exists? filename
        puts "Skipping existing file: '%s'..." % filename
        html << img_tag(filename)
      else
        puts "Saving '%s'..." % filename
        img = a[/^\/\//] && 'http:' + a || a
        IO.binwrite(filename, open(img).read)
        html << img_tag(filename)
      end
    end

    save_and_open_html_file
  end

  def save_and_open_html_file
    save_html_file
    system 'open', html_file
  end

  def save_html_file
    IO.write(html_file, html.join('<br />'))
  end

  def doc
    @doc ||= Mechanize.new.get(url)
  end

  def links
    @links ||= doc.links
  end

  def images
    @images ||= doc.images.inject([]) do |arr,img|
      attrs = img.node.attributes rescue {}
      data_src = attrs['data-src'].value rescue ''
      if data_src[/(^|\W)i[.]imgur/i]
        arr.push data_src.sub(/\w(?=[.][^.\/]+$)/i, '')
      end
      arr
    end
    # @images ||= links.select{|a| a.href =~ /(^|\W|\/)i[.]imgur/i }
  end

  def folder
    @folder ||= args[1] || url.sub(/\/all(\/|$)/i, '\1').split(?/).last rescue nil
  end

  def download_path
    @download_path ||= File.join(ENV['HOME'], 'Downloads', 'rippers', 'imgur')
  end

  def uniq_folder(date=Date.today, count=0, suffix=folder)
    @uniq_folder ||= begin
                       cd_to download_path
                       d = [date.to_s, '%03d' % count, suffix].compact.join(?-)
                       File.exist?(d) ? uniq_folder(date, count + 1, suffix) : d
                     end
  end

  def album_path
    @album_path ||= File.join(download_path, uniq_folder)
  end

  def cd_to(dir)
    FileUtils.mkdir_p(dir)
    Dir.chdir(dir)
  end

  def html_file
    'all.html'
  end

  def html
    @html ||= [css]
  end

  def img_tag(file)
    format('<img src="%s" />', File.basename(file))
  end

  def css
    <<-"CSS"
  <style type="text/css">
    img {
      width: 90%;
      margin: 10px 0px;
      padding: 0;
      border: solid 1px green;
    }
  </style>
    CSS
  end

  def parse_options
    args.options { |opts|
      opts.on('-h', '--help', 'print this message') do
        options.show_help = true
      end
    }.parse!
  end

  def options
    @options ||= OpenStruct.new.tap do |opts|
      # default options go here
      # or pass them to #new as a hash

      opts.show_help = false
    end
  end
end

#Imgur.folder 'http://imgur.com/a/opmvJ'
#Imgur.folder 'http://imgur.com/a/Bocu6'
#Imgur.folder 'http://imgur.com/a/vJNd5'
#Imgur.folder 'http://imgur.com/a/NZrZ0', 'hyouka'

# commented out because it is no longer a self-contained
# script:

# Imgur.folder ARGV[0] || `pbpaste`, ARGV[1]

