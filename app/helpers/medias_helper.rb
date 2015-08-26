module MediasHelper
  # From: https://github.com/twitter/twitter-text/blob/master/rb/lib/twitter-text/regex.rb
  TWITTER_HASHTAG_ALPHA = /[\p{L}\p{M}]/
  TWITTER_HASHTAG_ALPHANUMERIC = /[\p{L}\p{M}\p{Nd}_\u200c\u0482\ua673\ua67e\u05be\u05f3\u05f4\u309b\u309c\u30a0\u30fb\u3003\u0f0b\u0f0c\u0f0d]/
  TWITTER_HASHTAG_BOUNDARY = /\A|\z|[^&\p{L}\p{M}\p{Nd}_\u200c\u0482\ua673\ua67e\u05be\u05f3\u05f4\u309b\u309c\u30a0\u30fb\u3003\u0f0b\u0f0c\u0f0d]/
  TWITTER_HASHTAG_REGEXP = /(#{TWITTER_HASHTAG_BOUNDARY})(#|＃)(#{TWITTER_HASHTAG_ALPHANUMERIC}*#{TWITTER_HASHTAG_ALPHA}#{TWITTER_HASHTAG_ALPHANUMERIC}*)/io

  def parse_text(text)
    renderer = Redcarpet::Render::HTML.new(link_attributes: { target: '_blank' })
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, no_intra_emphasis: true)
    text = markdown.render(text)
    text.html_safe.chomp
  end

  def parse_translation(translation, provider)
    text = translation[:text]
    text = self.send("#{provider}_parse_translation", text) if !provider.blank? && self.respond_to?("#{provider}_parse_translation")
    text = parse_text(text).encode('UTF-8', invalid: :replace)
    text.html_safe
  end

  def twitter_parse_translation(text)
    text = text.gsub(TWITTER_HASHTAG_REGEXP, '\1<a href="https://twitter.com/hashtag/\3" target="_blank">\2\3</a>')
    text.gsub(/([@＠])([a-zA-Z0-9_]{1,20})/, '<a href="https://twitter.com/\2" target="_blank">\1\2</a>')
  end

  def instagram_parse_translation(text)
    text = text.gsub(TWITTER_HASHTAG_REGEXP, '\1<a href="https://instagram.com/explore/tags/\3" target="_blank">\2\3</a>')
    text = text.gsub(/@([a-zA-Z0-9_]+)/, '<a href="http://instagram.com/\1" target="_blank">@\1</a>')
  end

  def include_twitter_tags(project, collection, item, level, site)
    if level === 'item'
      image = URI.join(site, 'medias/', 'embed/', project + '/', URI.encode(collection) + '/', "#{item}.png")

      tag(:meta, name: 'twitter:card', content: 'photo') + "\n" +
      tag(:meta, name: 'twitter:site', content: BRIDGE_CONFIG['twitter_handle']) + "\n" +
      tag(:meta, name: 'twitter:image', content: image.to_s) + "\n"
    end
  end

  def short_url_for(project, collection, item)
    require 'bitly'
    url = [BRIDGE_CONFIG['bridgembed_host'], 'medias', 'embed', project, collection, item].join('/')
    begin
      bitly = Bitly.client.shorten(url)
      bitly.short_url
    rescue
      url
    end
  end

  def get_translation_direction(translation, provider)
    text = parse_translation(translation, provider)
    get_text_direction(text)
  end

  def get_comment_direction(comment)
    text = parse_text(comment[:comment])
    get_text_direction(text)
  end

  def get_text_direction(text)
    direction = text.direction
    direction == 'bidi' ? 'rtl' : direction
  end

  def include_google_analytics_tag
    code = BRIDGE_CONFIG['google_analytics_code']
    if code.blank?
      ''
    else
      content = "(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)})(window,document,'script','//www.google-analytics.com/analytics.js','ga');ga('create', '%s', 'auto');ga('send', 'pageview');"
      javascript_tag(content % code)
    end
  end
end
