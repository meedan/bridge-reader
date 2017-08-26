class Bot::Screenshot
  def self.take_screenshot(url, output)
    fetcher = Chromeshot::Screenshot.new debug_port: 9222
    fetcher.take_screenshot!(url: url, output: output)
  end
end
