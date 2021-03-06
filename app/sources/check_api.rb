require 'bridge_cache'
require 'bridge_webhooks'
require 'check_api_client'

module Sources
  class CheckApi < Base
    include Bridge::Cache
    include Bridge::Webhooks
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
      get_project if @team_id.nil?
      query = execute_query(ProjectMediaQuery, variables: { ids: get_ids(project_media,project,@team_id), annotation_types: "translation,translation_status" }).data
      unless query.nil?
        item_to_hash(query.project_media) if query.project_media.annotations_count.to_i > 0
      end
    end

    def get_collection(project, project_media = nil)
      get_project if @team_id.nil?
      # Return the project medias of a Check project
      query = execute_query(ProjectQuery, variables: { ids: get_ids(project,@team_id), annotation_types: "translation,translation_status" }).data
      unless query.nil?
        get_project_media_with_translations(query.project.project_medias.edges).collect { |t| item_to_hash(t)}
      end
    end

    def get_project(project = nil, project_media = nil)
      # Return the projects of a Check Team
      query = execute_query(TeamQuery, variables: { slug: @project }).data
      unless query.nil?
        @team_id = query.team.dbid
        get_projects_info(query.team.projects.edges, query.team.description)
      end
    end

    def get_ids(*args)
      args.join(',')
    end

    def get_projects_info(projects, team_description = '')
      get_projects_with_translations(projects).collect { |p| { name: p.title, id: p.dbid.to_s, summary: p.description, project: @project, project_summary: team_description }}
    end

    def get_projects_with_translations(projects)
      projects.map(&:node).find_all { |p| !get_project_media_with_translations(p.project_medias.edges).empty? }
    end

    def get_project_media_with_translations(pms)
      pms.map(&:node).find_all { |pm| pm.annotations_count.to_i > 0 }
    end

    def execute_query(query, variables = {})
      Client.query(query, variables)
    end

    def self.base_config(_payload)
      {
        info: { 'type' => 'check_api' }
      }
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

  end
end
