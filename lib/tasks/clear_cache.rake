namespace :bridgembed do
  task :clear_html_cache do
    FileUtils.rm_rf File.join(Rails.root, 'public', 'cache')
  end

  task :clear_screenshot_cache do
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots')
  end

  task clear_pender_cache: :environment do
    Rails.cache.delete_matched(/^pender:/)
  end

  task clear_all_cache: :environment do
    Rake::Task['bridgembed:clear_html_cache'].execute
    Rake::Task['bridgembed:clear_screenshot_cache'].execute
    Rake::Task['bridgembed:clear_pender_cache'].execute
  end
end
