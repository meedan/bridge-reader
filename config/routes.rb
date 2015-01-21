Bridgembed::Application.routes.draw do
  root 'medias#index'
  get 'medias/embed/:milestone', to: 'medias#embed'
end
