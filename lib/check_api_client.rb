require "graphql/client"
require "graphql/client/http"

module Check
  @config = BRIDGE_PROJECTS['check-api'].except('type')
  @graphql_uri = URI.join(@config['check_api_host'], @config['check_api_graphql']).to_s
  @relay_uri = URI.join(@config['check_api_host'], @config['check_api_relay']).to_s
  # TODO Get token from config
  HTTPAdapter = GraphQL::Client::HTTP.new(@graphql_uri) do
    def headers(context)
      { "X-Check-Token" => "dev" }
    end
  end

  Client = GraphQL::Client.new(
    schema: URI.parse(@relay_uri).read.to_s,
    execute: HTTPAdapter
  )

   TeamQuery = Client.parse <<-'GRAPHQL'
     query($slug:String!) { team(slug: $slug) { dbid, description, projects { edges { node { title, dbid, description } } } } }
    GRAPHQL

   ProjectQuery = Client.parse <<-'GRAPHQL'
     query($ids:String!) {
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
               language
               translations_count
               media {
                 dbid
                 quote
               }
             }
           }
         }
       }
    }
    GRAPHQL

   ProjectMediaQuery = Client.parse <<-'GRAPHQL'
     query($ids:String!) {
       project_media(ids: $ids) {
         dbid
         url
         created_at
         user {
           name
         }
         language
         translations_count
         media {
           dbid
           quote
         }
       }
    }
   GRAPHQL

   AnnotationsQuery = Client.parse <<-'GRAPHQL'
     query {
       root {
         annotations {
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
       }
     }
   GRAPHQL

end
