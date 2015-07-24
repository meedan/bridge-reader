Bridgembed::Application.routes.draw do
  get 'medias/embed/:project/(:collection/(:item))', to: 'medias#embed', constraints: {
    project: /[0-9a-zA-Z_-]+/,
    collection: /[0-9a-zA-Z_-]+/,
    item: /[0-9a-zA-Z_-]+/
  }
  post 'medias/notify/:project/(:collection/(:item))', to: 'medias#notify', constraints: {
    project: /[0-9a-zA-Z_-]+/,
    collection: /[0-9a-zA-Z_-]+/,
    item: /[0-9a-zA-Z_-]+/
  }
end
