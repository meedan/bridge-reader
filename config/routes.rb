Bridgembed::Application.routes.draw do
  get 'medias/embed/:type/:id', to: 'medias#embed'
  get 'medias/all', to: 'medias#all'
  post 'medias/notify', to: 'medias#notify'
end
