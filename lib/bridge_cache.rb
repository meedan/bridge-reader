require 'bridge_pender'
require 'bridge_cc_deville'
require 'smartshot'

module Bridge
  module Cache
    def clear_cache(project, collection, item)
      FileUtils.rm_rf(cache_path(project, collection, item))
      notify_cc_service(project, collection, item)
      true
    end

    def cache_path(project, collection, item)
      self.file_path(project, collection, item, 'cache', 'html')
    end

    def cache_exists?(project, collection, item)
      File.exists?(cache_path(project, collection, item))
    end

    def screenshot_exists?(project, collection, item)
      File.exists?(screenshot_path(project, collection, item))
    end

    def generate_cache(object, project, collection, item, site = BRIDGE_CONFIG['bridgembed_host'])
      # Check first if item exists
      level = get_level(project, collection, item)
      entries = get_entries_from_source(object, collection, item, level)
      clear_cache(project, collection, item) and return if entries.blank?
      path = cache_path(project, collection, item)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
      new_item = !File.exists?(path)
      save_cache_file(object, project, collection, item, level, entries, site)
      object.notify_new_item(collection, item) if new_item
      notify_cc_service(project, collection, item)
    end

    def remove_screenshot(project, collection, item)
      FileUtils.rm_rf(screenshot_path(project, collection, item))
      notify_cc_service(project, collection, item, 'png')
    end

    def screenshot_path(project, collection, item)
      self.file_path(project, collection, item, 'screenshots', 'png')
    end

    def generate_screenshot(project, collection, item, css = '')
      output = screenshot_path(project, collection, item)
      if BRIDGE_CONFIG['cache_embeds'] && File.exists?(output)
        # Cache file will be returned
      else
        url = self.screenshot_url(project, collection, item, css)
        level = self.get_level(project, collection, item)
        self.take_screenshot(url, output, level)
      end
      output
    end

    def take_screenshot(url, output, level)
      FileUtils.mkdir_p(File.dirname(output))
      tmp = Tempfile.new(['screenshot', '.png']).path
      Bot::Screenshot.take_screenshot(url, tmp)
      level === 'item' ? post_process_screenshot(tmp, output) : FileUtils.cp(tmp, output)
      FileUtils.rm_f(tmp)
    end

    def post_process_screenshot(tmp, output)
      image = MiniMagick::Image.open(tmp)

      w, h = image.width, image.height
      ratio = w.to_f / h.to_f
      extent = [w, h]

      w = h * 2 if ratio < 2
      h = w / 2 if ratio > 2

      image.combine_options do |c|
        c.gravity 'center'
        c.extent [w, h].join('x')
      end
      image.write(output)
    end

    def notify_cc_service(project, collection, item, format = nil)
      return if BRIDGE_CONFIG['cc_deville_host'].blank?
      url = [BRIDGE_CONFIG['bridgembed_host'], 'medias', 'embed', project, URI.encode(collection), item].reject{ |part| part.blank? }.join('/')
      url += '.' + format unless format.blank?
      cc = Bridge::CcDeville.new(BRIDGE_CONFIG['cc_deville_host'], BRIDGE_CONFIG['cc_deville_token'], BRIDGE_CONFIG['cc_deville_httpauth'])
      cc.clear_cache(url)
    end

    protected

    def get_level(project, collection, item)
      if !item.blank?
        'item'
      elsif !collection.blank?
        'collection'
      else
        'project'
      end
    end

    def get_entries_from_source(object, collection, item, level)
      pender = Bridge::Pender.new BRIDGE_CONFIG['pender_token']
      entries = {}.with_indifferent_access
      level_mapping(level).each do |l|
        entries[l] = pender.send("parse_#{l}", object.send("get_#{l}", collection, item))
      end
      entries[level].blank? ? [] : entries
    end

    def level_mapping(level)
      mapping = {
        'project' => [:project],
        'collection' => [:project, :collection],
        'item' => [:project, :collection, :item],
      }
      mapping[level]
    end

    def save_cache_file(object, project, collection, item, level, entries, site = nil)
      path = self.get_components(project, collection, item).join('-')
      av = ActionView::Base.new(Rails.root.join('app', 'views'))
      av.assign(entries: entries, project: project, collection: collection,
                item: item, site: site, level: level, path: path)
      ActionView::Base.send :include, MediasHelper
      content = av.render(template: "medias/embed-#{level}.html.erb", layout: "layouts/application.html.erb")
      File.atomic_write(cache_path(project, collection, item)) do |file|
        file.write(content)
      end
    end

    def screenshot_url(project, collection, item, css = '')
      url = [BRIDGE_CONFIG['bridgembed_host_private'], 'medias', 'embed', project, URI.encode(collection), item].join('/') + "?t=#{Time.now.to_i}&template=screenshot"
      url += "#css=#{css}" unless css.blank?
      url
    end

    def get_components(project, collection, item)
      [project, collection, item].reject(&:empty?)
    end

    def file_path(project, collection, item, basedir, extension)
      path = self.get_components(project, collection, item)
      File.join(Rails.root, 'public', basedir, path) + '.' + extension
    end
  end
end
