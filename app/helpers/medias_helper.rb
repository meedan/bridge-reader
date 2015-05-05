module MediasHelper
  # From: https://github.com/twitter/twitter-text/blob/master/rb/lib/twitter-text/regex.rb
  TWITTER_HASHTAG_ALPHA = /[\p{L}\p{M}]/
  TWITTER_HASHTAG_ALPHANUMERIC = /[\p{L}\p{M}\p{Nd}_\u200c\u0482\ua673\ua67e\u05be\u05f3\u05f4\u309b\u309c\u30a0\u30fb\u3003\u0f0b\u0f0c\u0f0d]/
  TWITTER_HASHTAG_BOUNDARY = /\A|\z|[^&\p{L}\p{M}\p{Nd}_\u200c\u0482\ua673\ua67e\u05be\u05f3\u05f4\u309b\u309c\u30a0\u30fb\u3003\u0f0b\u0f0c\u0f0d]/

  def parse_text(text)
    renderer = Redcarpet::Render::HTML.new(link_attributes: { target: '_blank' })
    markdown = Redcarpet::Markdown.new(renderer, autolink: true)
    text = markdown.render(text)
    text.html_safe.chomp
  end

  def parse_translation(translation)
    provider, text = translation[:provider], translation[:translation]
    text = self.send("#{provider}_parse_translation", text) if !provider.blank? && self.respond_to?("#{provider}_parse_translation")
    text = parse_text(text)
    text.html_safe
  end

  def twitter_parse_translation(text)
    text = text.gsub(/(#{TWITTER_HASHTAG_BOUNDARY})(#|＃)(#{TWITTER_HASHTAG_ALPHANUMERIC}*#{TWITTER_HASHTAG_ALPHA}#{TWITTER_HASHTAG_ALPHANUMERIC}*)/io, '\1<a href="https://twitter.com/hashtag/\3" target="_blank">\2\3</a>')
    text.gsub(/([@＠])([a-zA-Z0-9_]{1,20})/, '<a href="https://twitter.com/\2" target="_blank">\1\2</a>')
  end

  def instagram_parse_translation(text)
    text.gsub(/@([a-zA-Z0-9_]+)/, '<a href="http://instagram.com/\1" target="_blank">@\1</a>')
  end

  def include_twitter_tags_if_needed(entries, type, id, site)
    if entries.size == 1 && type == 'link'
      url = URI.join(site, 'medias/', 'embed/', type + '/', "#{id}.png")
      tag(:meta, name: 'twitter:card', content: 'photo') + "\n" +
      tag(:meta, name: 'twitter:site', content: BRIDGE_CONFIG['twitter_handle']) + "\n" +
      tag(:meta, name: 'twitter:image', content: url.to_s) + "\n"
    end
  end
end
