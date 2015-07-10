Bridgembed::Application.routes.draw do
  get 'medias/embed/:type/:id', to: 'medias#embed'
  get 'medias/all', to: 'medias#all'
  post 'medias/notify', to: 'medias#notify'

  # Legacy: ensure compatibility with version 0.5
  get 'medias/embed/:id', to: redirect('/medias/embed/milestone/%{id}')
end
