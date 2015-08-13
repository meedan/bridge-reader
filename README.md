Bridgembed
==========

[![Code Climate](https://codeclimate.com/repos/549c8a48e30ba06537002021/badges/2e1f5ed3a05c045248dc/gpa.svg)](https://codeclimate.com/repos/549c8a48e30ba06537002021/feed) 
[![Test Coverage](https://codeclimate.com/repos/549c8a48e30ba06537002021/badges/2e1f5ed3a05c045248dc/coverage.svg)](https://codeclimate.com/repos/549c8a48e30ba06537002021/feed)

A Bridge component, in Ruby On Rails, to generate embeds for media items.

![Workflow](doc/workflow.png?raw=true "Workflow")

![Code Flow](doc/codeflow.png?raw=true "Code Flow")

### Installing the system

* Copy config/bridgembed.yml.example to config/bridgembed.yml and set the configurations
* Set the projects at config/projects
* Copy config/database.yml.example to config/database.yml and configure your database
* Install the dependencies: `bundle install`
* Copy `config/initializers/secret_token.rb.example` to `config/initializers/secret_token.rb`
* Run `rake secret` and add the resulting key to `config/initializers/secret_token.rb`
* Add the google certificate `google.p12` (ask a Meedani for a copy) in your home directory.
* Run `rake db:migrate`
* Start the server

### Editing the Sass

* Install the Bridge-embed-ui dependences in *package.json* with `npm install` — this gives you gulp and browsersync.
* At the top level of the sass theme, there is a central Sass file that `@imports` other sass files.
* Some of these Sass files are managed with Bower (which is added to the path in the gulpfile).
* The bower libraries are not in version control, you must first install them with `bundle exec rake bower:install` (or just `bower install`).
* Make sure you run the rails app (per above) and hit the route to trigger the cached embed codes. 
* `gulp` to start watching the Sass files.
* Navigate to `http://localhost:3001/dev/4col-basic.html` *NOTE: Rails server runs on a different port, and BrowserSync proxies the connection ... Unfortunately it seems to be failing in the case of the js embeds for unknown reasons (See #100229448). For now you must manually check the embed URLs in your dev match the port of your Rails host. — CB 2015 August 12*
* You should see confirmation that browser sync loaded in the browser. 
* Save your sass file it should injet the new CSS without a full page load. 
* It should refresh when you change any of the Sass files.
* Open the "external" link on your phones and tablets on the same network.

## Editing the HTML

If you need to edit the template (ie by editing the view files, which contain erb) you'll need to disable caching, rebuild the template, then probably turn caching back on to keep working with the stylesheet. In bridgeembed.yml set `cache_embeds: true`.

To flush the cache once, use `rake bridgembed:clear_all_cache`.

### Running the tests

* Run `bundle exec rake test`
* Or just run specific tests like this: `bundle exec ruby ./test/helpers/medias_test.rb`
