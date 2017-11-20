require 'chromeshot'

port = BRIDGE_CONFIG['chrome_debug_port']
unless system("lsof -i:#{port}", out: '/dev/null')
  puts "Starting Chromeshot on port #{port}"
  Chromeshot::Screenshot.setup_chromeshot(port)
end
