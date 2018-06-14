require 'bridge_cache'

namespace :bridgembed do
  task build_cache: :environment do
    include Bridge::Cache

    BRIDGE_PROJECTS.each do |project, config|
      puts "[#{Time.now}] - Building cache for project #{project}"
      
      object = nil
      begin
        klass = 'Sources::' + config['type'].camelize
        object = klass.constantize.new(project, config.except('type'))
      rescue NameError
        puts "Skipping #{project} (type not supported)"
      end
      next if object.nil?

      object.get_project.each do |collection|
        collection = collection['name']
        items = object.get_collection(collection, nil, true)
        
        puts "[#{Time.now}] - - - Building cache for collection #{collection} (#{items.size} items)"
        
        items.each do |item|
          id = item[:id]

          puts "[#{Time.now}] - - - - - Building HTML cache for item #{id}"
          generate_cache(object, project, collection, id) unless cache_exists?(project, collection, id)
          
          puts "[#{Time.now}] - - - - - Building screenshot cache for item #{id}"
          begin
            generate_screenshot(project, collection, id) unless screenshot_exists?(project, collection, id)
          rescue
            puts "[#{Time.now}] - - - - - - - Failed when building screenshot cache for item #{id}!"
          end
        end

        generate_cache(object, project, collection, '') unless cache_exists?(project, collection, '')
        begin
          generate_screenshot(project, collection, '') unless screenshot_exists?(project, collection, '')
        rescue
          puts "[#{Time.now}] - - - - - - - Failed when building screenshot cache for collection #{collection}!"
        end
      end
    end
  end

  task rebuild_cache: :environment do
    Rake::Task['bridgembed:clear_all_cache'].execute
    Rake::Task['bridgembed:build_cache'].execute
  end
end
