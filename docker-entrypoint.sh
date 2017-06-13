#!/bin/bash

# Rake tasks
if [ "$RAILS_ENV" == "test" ]
then
  bundle exec rake db:drop
fi
bundle exec rake db:create
bundle exec rake db:migrate

# Google Chrome
LC_ALL=C google-chrome --headless --hide-scrollbars --remote-debugging-port=9222 --disable-gpu --no-sandbox --ignore-certificate-errors &
sleep 3


# Web server
mkdir -p /app/tmp/pids
rm -f /app/tmp/pids/server-$RAILS_ENV.pid
if [ "$RAILS_ENV" == "test" ]
then
  bundle exec rails s -b 0.0.0.0 -p $SERVER_PORT -P /app/tmp/pids/server-$RAILS_ENV.pid
else
  puma="/app/tmp/puma-$RAILS_ENV.rb"
  cp config/puma.rb $puma
  echo "pidfile '/app/tmp/pids/server-$RAILS_ENV.pid'" >> $puma
  echo "port $SERVER_PORT" >> $puma
  bundle exec puma -C $puma
fi
