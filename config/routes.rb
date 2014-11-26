Bridgembed::Application.routes.draw do
  get 'medias/embed/:milestone', to: 'medias#embed'
end
