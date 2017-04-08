Bridge Reader
=============

[![Code Climate](https://codeclimate.com/repos/549c8a48e30ba06537002021/badges/2e1f5ed3a05c045248dc/gpa.svg)](https://codeclimate.com/repos/549c8a48e30ba06537002021/feed)
[![Test Coverage](https://codeclimate.com/repos/549c8a48e30ba06537002021/badges/2e1f5ed3a05c045248dc/coverage.svg)](https://codeclimate.com/repos/549c8a48e30ba06537002021/feed)
[![Travis](https://travis-ci.org/meedan/bridge-reader.svg?branch=develop)](https://travis-ci.org/meedan/bridge-reader/)

A Bridge component, in Ruby On Rails, to generate embeds for media items.

![Workflow](doc/workflow.png?raw=true "Workflow")

![Code Flow](doc/codeflow.png?raw=true "Code Flow")

### Installing the system

* Copy `config/bridgembed.yml.example` to `config/bridgembed.yml` and set the configurations appropriately
* Add configuration files for projects at `config/projects/<environment>/<project-name>.yml`
* Copy `config/database.yml.example` to `config/database.yml` and configure your database appopriately
* Install the dependencies: `bundle install`
* Copy `config/initializers/secret_token.rb.example` to `config/initializers/secret_token.rb`
* Run `bundle exec rake db:migrate`
* Start the server: `bundle exec rails s`

### Editing the Sass

* Install the Bridge-embed-ui dependences in *package.json* with `npm install` — this gives you gulp and browsersync.
* At the top level of the sass theme, there is a central Sass file that `@imports` other sass files.
* Make sure you run the rails app (per above) and hit the route to trigger the cached embed codes.
* `gulp` to start watching the Sass files.
* Navigate to `http://localhost:3000/medias/embed/test`
* You should see confirmation that browser sync loaded in the browser.
* Save your sass file.
* Refresh the browser manually to see your changes (Browsersync is not working at the moment.)

## Editing the HTML

If you need to edit the template (ie by editing the view files, which contain erb) you will want to flush the cache after each HTML change with: `rake bridgembed:clear_all_cache`.

### Running the tests

* Run `bundle exec rake test`
* Or just run specific tests like this: `bundle exec ruby ./test/helpers/medias_test.rb`

### Special note for Mac El Capitan Users

If you get a Faraday SSL error it's likely trying to read a certificate from an incorrect directory. Checkout http://toadle.me/2015/04/16/fixing-failing-ssl-verification-with-rvm.html and Open-SSL tools to diagnose
https://github.com/mislav/ssl-tools
