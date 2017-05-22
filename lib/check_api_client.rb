require "graphql/client"
require "graphql/client/http"

module Check

  @graphql_uri = URI.join(BRIDGE_CONFIG['check_api_url'], 'api/graphql').to_s
  @relay_uri = URI.join(BRIDGE_CONFIG['check_api_url'], 'relay.json').to_s

  HTTPAdapter = GraphQL::Client::HTTP.new(@graphql_uri) do
    def headers(context)
      { "X-Check-Token" => BRIDGE_CONFIG['check_api_token'] }
    end
  end

  Client = GraphQL::Client.new(
    schema: URI.parse(@relay_uri).read.to_s,
    execute: HTTPAdapter
  )

  TeamQuery = Client.parse <<-'GRAPHQL'
    query($slug:String!) {
      team(slug: $slug) {
        dbid
        description
        projects {
          edges {
            node {
              title
              dbid
              description
              project_medias {
                edges {
                  node {
                    annotations_count(annotation_type: "translation")
                  }
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL

  ProjectQuery = Client.parse <<-'GRAPHQL'
    query($ids:String!,$annotation_types:String!) {
      project(ids: $ids) {
        dbid
        title
        description
        project_medias {
          edges {
            node {
              dbid
              url
              created_at
              user {
                name
              }
              language_code
              annotations_count(annotation_type: "translation")
              annotations(annotation_type: $annotation_types) {
                edges {
                  node {
                    dbid
                    annotated_id
                    annotation_type
                    content
                    created_at
                    annotator {
                      name
                    }
                  }
                }
              }
              media {
                dbid
                quote
                url
              }
            }
          }
        }
      }
   }
  GRAPHQL

   ProjectMediaQuery = Client.parse <<-'GRAPHQL'
     query($ids:String!,$annotation_types:String!) {
       project_media(ids: $ids) {
         dbid
         url
         created_at
         user {
           name
         }
         language_code
         annotations_count(annotation_type: "translation")
         annotations(annotation_type: $annotation_types) {
           edges {
             node {
               dbid
               annotated_id
               annotation_type
               content
               created_at
               annotator {
                 name
               }
             }
           }
         }
         media {
           dbid
           quote
           url
         }
       }
    }
   GRAPHQL

end
