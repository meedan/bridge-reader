namespace :bridgembed do
  task :clear_milestone_cache do
    FileUtils.rm Dir.glob(File.join(Rails.root, 'public', 'cache', '*.html'))
  end

  task clear_link_cache: :environment do
    Rails.cache.delete_matched(/^http/)
  end

  task clear_all_cache: :environment do
    Rake::Task['bridgembed:clear_milestone_cache'].execute
    Rake::Task['bridgembed:clear_link_cache'].execute
  end
end
