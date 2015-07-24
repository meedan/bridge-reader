BRIDGE_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/bridgembed.yml")[Rails.env]

WebMock.allow_net_connect!

Bitly.use_api_version_3

Bitly.configure do |config|
  config.api_version = 3 
  config.access_token = BRIDGE_CONFIG['bitly_key'] 
end

BRIDGE_PROJECTS = {}
Dir.glob("#{Rails.root.to_s}/config/projects/#{Rails.env}/*.yml").each do |config_file|
  name = File.basename(config_file, '.yml')
  BRIDGE_PROJECTS[name] = YAML.load_file(config_file)
end
