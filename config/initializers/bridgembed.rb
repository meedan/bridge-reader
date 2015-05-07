BRIDGE_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/bridgembed.yml")[Rails.env]

WebMock.allow_net_connect!

Bitly.use_api_version_3

Bitly.configure do |config|
  config.api_version = 3 
  config.access_token = BRIDGE_CONFIG['bitly_key'] 
end
