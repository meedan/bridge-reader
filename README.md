Bridgembed
==========

A Bridge component, in Ruby On Rails, to generate embeds for media items.

### Installing the system

* Copy config/bridgembed.yml.example to config/bridgembed.yml and set the configurations
* Copy config/database.yml.example to config/database.yml and configure your database
* Install the dependencies: `bundle install`
* Run `rake db:migrate`
* Start the server

### Using the system

You can embed a worksheet as a milestone by calling `http://yourhostname/medias/embed/<worksheet title>`.
