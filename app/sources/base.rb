module Sources
  class Base
    def initialize(project, config = {})
      @project = project
      @config = config
      raise "Cannot directly instantiate this class" if self.class == Base
    end

    def project
      @project
    end

    def to_s
      # Generate a string representation of this instance
      super
    end

    def get_item(collection, item)
      # Return a single item from a collection
      # Please return something like the structure below.
      # It's advisable to cache this structure.
      #
      # {
      #   id: item
      #   source_text: source text
      #   source_lang: source lang
      #   link: source link
      #   timestamp:
      #   translations: [
      #     {
      #       translator_name:
      #       translator_url:
      #       timestamp:
      #       text:
      #       lang:
      #       comments: [
      #         {
      #           commenter_name:
      #           commenter_url:
      #           timestamp:
      #           comment:
      #         },
      #         (...)
      #       ]
      #     },
      #     (...)
      #   ],
      #   source: used internally (links to the source class instance that generated this)
      #   index: where does this translation is located in the respective collection
      # }
      {}
    end

    def get_collection(collection, item = nil, force = false)
      # Return a list of <entries> as [<entry-1>, <entry-2>, ..., <entry-n>]
      # Each <entry-i> is defined as in `get_entry` method above
      []
    end

    def get_project(collection = nil, item = nil)
      # Return a list of collection ids, like: [ <collection-id-1>, <collection-id-2>, ..., <collection-n> ]
      []
    end

    def notify_availability(item, available = false)
      # Bridge::Pender calls this method when some item is not available
    end

    def notify_new_item(collection, item, new_item = true)
      # Bridge::Cache calls this method when caching this item for the first time
    end

    def parse_notification(collection, item, payload = {})
      # MediasController#notify calls this method when notified to alter some embed
    end
  end
end
