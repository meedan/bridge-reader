namespace :bridgembed do
  task :clear_milestone_cache do
    FileUtils.rm Dir.glob(File.join(Rails.root, 'public', 'cache', '*.html'))
  end
end
