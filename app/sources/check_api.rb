require "graphql/client"
require "graphql/client/http"
require "check_api_client"

module Sources
  class CheckApi < Base
    include Bridge::Cache
    include Check

    # First, the methods overwritten from Source::Base

    def initialize(project, config = {})
      @project = project
      @config = config
      super
    end

    def to_s
      @project
    end

    def get_item(project, project_media)
      # Check Project Media -> return the project media
      ids = [project_media,project,@team_id].join(',')
      query = execute_query(ProjectMediaQuery, variables: { ids: ids })
      unless query.nil?
        item_to_hash(query.project_media) if query.project_media.translations_count.to_i > 0
      end
    end

    def get_collection(project, project_media = nil)
      # Return the project medias of a Check project
      ids = [project,@team_id].join(',')
      query = execute_query(ProjectQuery, variables: { ids: ids })
      unless query.nil?
        translations = query.project.project_medias.edges.map(&:node).find_all { |p| p.translations_count.to_i > 0 }
        translations.collect { |t| item_to_hash(t)}
      end
    end

    def get_project(project = nil, project_media = nil)
      # Return the projects of a Check Team
      query = execute_query(TeamQuery, variables: { slug: @project })
      @team_id = query.team.dbid
      query.team.projects.edges.map(&:node).collect { |node| { name: node.title, id: node.title, summary: node.description, project: @project, project_summary: query.team.description }}
    end

    protected

    def item_to_hash(pm)
      {
        id: pm.media.dbid.to_s,
        source_text: pm.media.quote,
        source_lang: pm.language,
        source_author: pm.user.name,
        link: pm.url.to_s,
        timestamp: pm.created_at,
        translations: self.translations(pm.dbid),
        source: pm.url,
        index: pm.media.dbid.to_s
      }
    end

    def translations(item)
      query = execute_query(AnnotationsQuery)
      unless query.nil?
        translation = query.root.annotations.edges.map(&:node).find { |t| t.annotation_type == 'translation' && t.annotated_id.to_i == item.to_i}
      end
      translation.nil? ? [] : translation_to_hash(translation)
    end

    def translation_to_hash(translation)
      content = JSON.parse(translation.content)
      [
        {
          translator_name: translation.annotator.name,
          translator_handle: "",
          translator_url: "",
          text: translation_field(content, 'translation_text'),
          lang: translation_field(content, 'translation_language'),
          timestamp: translation.created_at,
          comments: comments_from_translation(translation, content)
        }
      ]
    end

    def comments_from_translation(translation, content)
      comments = []
      notes = content.select { |field| field['field_name'] == 'translation_note'}
      notes.each do |comment|
        comments << {
          commenter_name: translation.annotator.name,
          commenter_url: '',
          comment: translation_field(content, 'translation_note'),
          timestamp: comment['created_at']
        }
      end
      comments
    end

    def translation_field(content, field_name)
      field = content.find { |field| field['field_name'] == field_name}
      field.nil? ? '' : field['value']
    end

    def execute_query(query, variables = {})
      result = Client.query(query, variables)
      result.data
    end
  end
end
