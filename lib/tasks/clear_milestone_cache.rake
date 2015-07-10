namespace :bridgembed do
  task :clear_milestone_cache do
    FileUtils.rm_rf File.join(Rails.root, 'public', 'cache', 'link')
    FileUtils.rm_rf File.join(Rails.root, 'public', 'cache', 'milestone')
  end

  task :clear_screenshot_cache do
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots')
  end

  task clear_link_cache: :environment do
    Rails.cache.clear
  end

  task clear_all_cache: :environment do
    Rake::Task['bridgembed:clear_milestone_cache'].execute
    Rake::Task['bridgembed:clear_link_cache'].execute
    Rake::Task['bridgembed:clear_screenshot_cache'].execute
  end
end
