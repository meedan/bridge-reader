puts "Start Chromeshot on port #{BRIDGE_CONFIG['chrome_debug_port']}"

Chromeshot::Screenshot.setup_chromeshot(BRIDGE_CONFIG['chrome_debug_port'])
