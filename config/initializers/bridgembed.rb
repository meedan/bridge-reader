BRIDGE_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/bridgembed.yml")[Rails.env]
WebMock.allow_net_connect!