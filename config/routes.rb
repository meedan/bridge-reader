Bridgembed::Application.routes.draw do
  get 'medias/embed/:milestone', to: 'medias#embed'
  get 'medias/all', to: 'medias#all'
end
