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

* Render a worksheet as a milestone by calling `http://yourhostname/medias/embed/milestone/<worksheet title>`.
* Embed a worksheet by adding a script tag like `<script src="http://yourhostname/medias/embed/milestone/<worksheet title>.js"></script>` to your HTML page. 
* Embed single links by just replacing `milestone` by `link` above, and use the link SHA1 hash instead of the milestone title.

### Editing the Sass

* Install the Bridge-embed-ui dependences in *package.json* with `npm install` — this gives you gulp and browsersync.
* At the top level of the sass theme, there is a central Sass file that `@imports` other sass files.
* Some of these Sass files are managed with Bower (which is added to the path in the gulpfile).
* The bower libraries are not in version control, you must first install them with `bundle exec rake bower:install` (or just `bower install`).
* Make sure you run the rails app (per above) and hit the route to trigger the cached embed codes. You should see the cached html filed like this: `public/cache/first_1424035717.html`
* `gulp` to start watching the Sass files.
* Navigate directly to the cached file like this: (exact path depends on your timestamped cache): `http://localhost:3000/cache/first_1424035717.html`
* Load the page and you should see confirmation that browser sync loaded in the browser. 
* Save your sass file it should injet the new CSS without a full page load. 
* Open the "external" link on your phones and tablets on the same network.

## Editing the HTML

If you need to edit the template (ie by editing the view files, which contain erb) you'll need to disable caching, rebuild the template, then probably turn caching back on to keep working with the stylesheet. In bridgeembed.yml set `cache_embeds: true`.

### Running the tests

* Run `bundle exec rake test`
* Or just run specific tests like this: `bundle exec ruby ./test/helpers/medias_test.rb`
