#!/bin/bash

# Create Mongo indexes if needed
cd ${DEPLOYDIR}/current
su ${DEPLOYUSER} -c 'bundle exec rake db:migrate'
su ${DEPLOYUSER} -c 'bundle exec rake test'
