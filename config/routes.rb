Bridgembed::Application.routes.draw do
  get 'medias/embed/:milestone', to: 'medias#embed'
  get 'medias/embed/:milestone/:link', to: 'medias#embed'
  get 'medias/all', to: 'medias#all'
  post 'medias/notify', to: 'medias#notify'
end
