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
      query = execute_query(ProjectMediaQuery, variables: { ids: get_ids(project_media,project,@team_id), annotation_types: "translation,translation_status" })
      unless query.nil?
        item_to_hash(query.project_media) if query.project_media.annotations_count.to_i > 0
      end
    end

    def get_collection(project, project_media = nil)
      # Return the project medias of a Check project
      query = execute_query(ProjectQuery, variables: { ids: get_ids(project,@team_id), annotation_types: "translation,translation_status" })
      unless query.nil?
        translations = query.project.project_medias.edges.map(&:node).find_all { |p| p.annotations_count.to_i > 0 }
        translations.collect { |t| item_to_hash(t)}
      end
    end

    def get_project(project = nil, project_media = nil)
      # Return the projects of a Check Team
      query = execute_query(TeamQuery, variables: { slug: @project })
      unless query.nil?
        @team_id = query.team.dbid
        query.team.projects.edges.map(&:node).collect { |node| { name: node.title, id: node.dbid.to_s, summary: node.description, project: @project, project_summary: query.team.description }}
      end
    end

    def get_ids(*args)
      args.join(',')
    end

    protected

    def item_to_hash(pm)
      user_name = pm.user ? pm.user.name : ''
      {
        id: pm.dbid.to_s,
        source_text: pm.media.quote,
        source_lang: pm.language_code,
        source_author: user_name,
        link: pm.media.url.to_s,
        timestamp: pm.created_at,
        translations: self.translations(pm.annotations),
        source: pm.url,
        index: pm.media.dbid.to_s
      }
    end

    def translations(translations)
      translation = get_translation_annotation(translations, 'translation')
      translation_status = get_translation_annotation(translations, 'translation_status')
      translation.nil? ? [] : translation_to_hash(translation, translation_status)
    end

    def get_translation_annotation(translations, annotation_type)
      translations.edges.map(&:node).find { |t| t.annotation_type == annotation_type }
    end

    def translation_to_hash(translation, status)
      content = JSON.parse(translation.content)
      [
        {
          translator_name: translation.annotator.name,
          translator_handle: "",
          translator_url: "",
          text: json_field(content, 'translation_text'),
          lang: json_field(content, 'translation_language'),
          timestamp: translation.created_at,
          comments: comments_from_translation(translation, content),
          approval: status_info(status)
        }
      ]
    end

    def status_info(status)
      return nil if status.nil?
      content = JSON.parse(status.content)
      approved = '1' if json_field(content, 'translation_status_status') == 'ready'
      approver = json_field(content, 'translation_status_approver')
      approver = JSON.parse(approver) unless approver.blank?
      {
        approved: approved,
        approver_name: approver['name'].to_s,
        approver_url: approver['url'].to_s
      }
    end

    def comments_from_translation(translation, content)
      comments = []
      notes = content.select { |field| field['field_name'] == 'translation_note'}
      notes.each do |comment|
        text = json_field(content, 'translation_note')
        unless text.blank?
          comments << {
            commenter_name: translation.annotator.name,
            commenter_url: '',
            comment: text,
            timestamp: comment['created_at']
          }
        end
      end
      comments
    end

    def json_field(content, field_name)
      field = content.find { |field| field['field_name'] == field_name}
      field.nil? ? '' : field['value']
    end

    def execute_query(query, variables = {})
      result = Client.query(query, variables)
      result.data
    end
  end

end
