namespace :test do
  task :coverage do
    require 'simplecov'
    SimpleCov.start 'rails' do
      coverage_dir 'public/coverage'
    end
    system "LC_ALL=C google-chrome --headless --hide-scrollbars --remote-debugging-port=9222 --disable-gpu --no-sandbox --ignore-certificate-errors &"
    Rake::Task['test'].execute
  end
end
