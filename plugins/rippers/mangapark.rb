#!/usr/bin/env ruby

require 'mechanize'
require 'fileutils'
require 'open-uri'
require 'pp'
require 'pry'

class MangaPark < BaseRipper
  register :mangapark

  class << self
    def url_patterns
      [
        /mangapark[.]me/i,
      ]
    end

    def matches?(url=`pbpaste`)
      return true if url_patterns.any?{|re| url[re] }
      false
    end

    def rip(args=ARGV.clone)
      new(args).tap(&:rip).tap(&:open_folders)
    end
  end

  attr_accessor :args
  def initialize(args=ARGV.clone)
    @args = args

    parse_options

    cd_to ripper_path
  end

  def ripper_name
    'mangapark'
  end

  def ripper_path
    @download_path ||= File.join(base_path, ripper_name)
  end

  def url
    @url ||= args[0] || `pbpaste`
    @url &&= @url.sub(/(\/c\d[^\/]*)\/.*/, '\1')
  end

  def url=(newurl)
    @url = newurl
    @url &&= @url.sub(/(\/c\d[^\/]*)\/.*/, '\1')
  end

  def url_parts(url=@url)
    url.sub(/^(https?:..)?[^\/]*[.]me\/manga\//, '').split(?/).map(&URI.method(:decode))
  end

  def parse_url(url=@url)
    uparts = url_parts(url)
    title   = uparts[0]
    stream  = uparts.find{|upart| upart[/^s\d+/] } || '0'
    stream &&= stream.sub(/^s/,'')
    stream &&= stream[/\D/] ? stream : format('%03d', stream.to_i)
    volume  = uparts.find{|upart| upart[/^v\d+/] } || '0'
    volume &&= volume.sub(/^v/,'')
    volume &&= volume[/\D/] ? volume : format('%03d', volume.to_i)
    chapter  = uparts.find{|upart| upart[/^c\d+/] } || '0'
    chapter &&= chapter.sub(/^c/,'')
    chapter &&= chapter[/\D/] ? chapter : format('%03d', chapter.to_i)
    {
      manga: title,
      stream: stream,
      volume: volume,
      chapter: chapter,
    }
  end

  def manga
    parse_url(url)[:manga]
  end

  def stream
    parse_url(url)[:stream]
  end

  def volume
    parse_url(url)[:volume]
  end

  def chapter
    parse_url(url)[:chapter]
  end

  def folder
    @folder ||= args[1] rescue nil
  end

  def default_folder
    Date.today.to_s.tap do |f|
      folder_path(f)
    end
  end

  def folder_path(folder)
    File.join(ripper_path, folder).tap do |f|
      FileUtils.mkdir_p(f, verbose: true)
      download_folders.push f unless download_folders.include? f
    end
  end

  def download_folders
    @download_folders ||= []
  end

  def open_folders
    download_folders.each do |df|
      system 'open', df
    end
  end

  def html_file(date=Date.today, count=1)
    @html_file ||= begin
                     name = format('%s-%03d.html', date, count)
                     File.exist?(name) ? html_file(date, count + 1) : name
                   end
  end

  def css
    <<-CSS
    <style type="text/css">
      h1 {
        padding: 28px 46px;
        border: solid 2px black;
        background-color: rgba(20,200,250,0.8);
        margin-top: 466px;
      }

      h1:first-child {
        margin-top: 50px;
      }

      .chlinks a {
        margin-left: 10%;
      }

      .chlinks a:first-child {
        margin-left: 2%;
      }

      img {
        width: 90%;
        border: solid 1px black;
        margin: 20px auto;
        background-color: rgba(0,0,0,0.15);
        padding: 10px;
        display: block;
      }
    </style>
    CSS
  end

  def img_tag(file)
    vol,ch,pg,ext = file.split(/[-.]/)

    chapter_links = [
      '<div class="chlinks">',
      '<a href="#%s%s">Prev Chapter</a>' % [vol.to_i, ch.to_i - 1],
      '<a href="#%s%s">Top of Chapter</a>' % [vol.to_i, ch.to_i],
      '<a href="#%s%s">Next Chapter</a>' % [vol.to_i, ch.to_i + 1],
      '</div>',
    ].join
    fmt = chapter_links + '<img src="%s" alt="%s" title="%s" />'

    if vol != @last_vol || ch != @last_ch
      @last_vol = vol
      @last_ch = ch

      fmt = format('<br/><h1 id="%s%s">v%s ch%s</h1><br/>%s%s', vol.to_i, ch.to_i, vol.to_i, ch.to_i, "\n", fmt)
    end

    format(fmt, file, file, file)
  end

  def save_html_file
    IO.write(html_file, [css, images.map(&method(:img_tag))].join('<br/>'))
  end

  def save_and_open_html_file
    save_html_file
    system 'open', html_file
  end

  def rip
    dest = folder || manga || default_folder
    cd_to File.join(ripper_path, dest)

    puts "Downloading Album: '%s'..." % dest

    next_link = url

    while next_link != nil
      puts format('Next Link => %s', next_link)
      page_doc = doc_for_url next_link

      self.url = next_link

      page_imgs = page_doc.images.select{|img| img.dom_class.to_s[/\bimg\b/] }
      page_imgs.each_with_index do |img,pg|
        filename = format('%s-%s-%03d.png', volume, chapter, pg)
        images.push filename

        if File.exist?(filename)
          puts 'Skip existing file "%s"...' % filename
          next_link = extract_next_link(page_doc)
          break log_next_link(next_link) if next_link == nil
          log_next_link(next_link)
          next
        end

        puts 'Saving "%s"...' % filename

        imgmech = Mechanize.new
        imgdoc = imgmech.get(img.src)
        imgdoc.save_as(filename)
        imgmech.shutdown
        # doc_for_url(img.src).save_as(filename)
      end

      next_link = ('http://mangapark.me' + page_doc.links.find{|a| a.text[/Next/] }.href)
      break log_next_link(next_link) if next_link == nil
      log_next_link(next_link)
    end

  ensure
    save_and_open_html_file
  end

  def log_next_link(nl)
    puts "Next Link: %s" % nl
    nl
  end

  def extract_next_link(page_doc)
    nlink = nil
    if link_tag = page_doc.links.find{|a| a.text[/Next\s/] }
      nlink = link_tag.href.sub(/^((https?:..)?(\w+[.])?mangapark.me\/)?/i, 'http://mangapark.me/') rescue nil
      return unless nlink.is_a?(String)
      return if parse_url(nlink)[:stream] != stream
    end
    nlink
  end

  def doc
    @doc ||= Mechanize.new.get(url)
  end

  def doc_for_url(url)
    ap doc_for_url: url
    docs[url] ||= Mechanize.new.get(url)
  end

  def docs
    @docs ||= {}.to_mash
  end

  def links
    @links ||= doc.links
  end

  def images
    @images ||= []
  end

  def parse_options
    return if options.parsed

    args.options { |opts|
      opts.on('-h', '--help', 'print this message') do
        options.show_help = true
      end
    }.parse!

    options.parsed = true
  end

  def options
    @options ||= OpenStruct.new.tap do |opts|
      # default options go here
      # or pass them to #new as a hash

      opts.show_help = false
      opts.parsed = false
    end
  end
end

