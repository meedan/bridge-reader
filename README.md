Bridgembed
==========

[![Code Climate](https://codeclimate.com/repos/549c8a48e30ba06537002021/badges/2e1f5ed3a05c045248dc/gpa.svg)](https://codeclimate.com/repos/549c8a48e30ba06537002021/feed) 
[![Test Coverage](https://codeclimate.com/repos/549c8a48e30ba06537002021/badges/2e1f5ed3a05c045248dc/coverage.svg)](https://codeclimate.com/repos/549c8a48e30ba06537002021/feed)

A Bridge component, in Ruby On Rails, to generate embeds for media items.

![Workflow](doc/workflow.png?raw=true "Workflow")

### Installing the system

* Copy config/bridgembed.yml.example to config/bridgembed.yml and set the configurations
* Copy config/database.yml.example to config/database.yml and configure your database
* Install the dependencies: `bundle install`
* Run `rake db:migrate`
* Start the server

### Using the system

You can render a worksheet as a milestone by calling `http://yourhostname/medias/embed/<worksheet title>`.
You can embed a worksheet by adding a script tag like `<script src="http://yourhostname/medias/embed/<worksheet title>.js"></script>` to your HTML page.

### Developing the Sass theme

* Install the Bridge-embed-ui dependences in *package.json* with `npm install` — this gives you grunt and browsersync
* There is a Sass file that `@imports` other sass files
* Some of the Sass files are managed with Bower
* The bower libraries are not in version control, you can install them with `rake bower:install`
* Run `gulp`

### Running the tests

* Just run `bundle exec rake test`
