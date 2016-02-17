# bridge-embed-base
# VERSION  0.0.1

FROM dreg.meedan.net/meedan/ruby
MAINTAINER sysops@meedan.com
ENV IMAGE dreg.meedan.net/bridge/embed

#
# SYSTEM CONFIG
#
ENV DEPLOYUSER bridgedeploy
ENV DEPLOYDIR /var/www/bridge-embed
ENV RAILS_ENV production
# ENV GITREPO git@github-bridgembed:meedan/bridge-embed.git

COPY ./docker/bin/* /opt/bin/
RUN chmod 755 /opt/bin/*.sh

RUN apt-get install -y imagemagick fonts-arphic-ukai fonts-arphic-uming fonts-ipafont-mincho fonts-ipafont-gothic fonts-unfonts-core

#
# APP CONFIG
#

# nginx for bridge-embed
COPY ./docker/config/nginx/bridge-embed /etc/nginx/sites-available/bridge-embed
RUN ln -s /etc/nginx/sites-available/bridge-embed /etc/nginx/sites-enabled/bridge-embed
RUN rm /etc/nginx/sites-enabled/default

#
# USER CONFIG
#

RUN useradd ${DEPLOYUSER} -s /bin/bash -m

#
# code deployment
#

RUN mkdir -p $DEPLOYDIR/latest && chown www-data:www-data /var/www && chmod 775 /var/www && chmod g+s /var/www


RUN chown -R ${DEPLOYUSER}:www-data ${DEPLOYDIR}
USER ${DEPLOYUSER}
# install the gems first so that we can more easily cache them and allow code changes to be made later
WORKDIR ${DEPLOYDIR}
COPY ./Gemfile ./latest/Gemfile
COPY ./Gemfile.lock ./latest/Gemfile.lock
RUN cd latest && echo "gem: --no-rdoc --no-ri" > ~/.gemrc && bundle install --deployment 

COPY . ./latest
USER root
RUN chown -R ${DEPLOYUSER}:www-data ${DEPLOYDIR}
USER ${DEPLOYUSER}
RUN mv ./latest ./bridge-embed-$(date -I) && ln -s ./bridge-embed-$(date -I) ./current
COPY ./docker/config/bridge-embed/database.yml ${DEPLOYDIR}/current/config/database.yml

RUN cp ${DEPLOYDIR}/current/config/initializers/secret_token.rb.example ${DEPLOYDIR}/current/config/initializers/secret_token.rb \
 && ln -s ${DEPLOYDIR}/shared/runtime/bridgembed.yml ${DEPLOYDIR}/current/config/ \
 && rm -rf ${DEPLOYDIR}/current/config/projects \
 && ln -s ${DEPLOYDIR}/shared/projects ${DEPLOYDIR}/current/config/ \
 && ln -s ${DEPLOYDIR}/shared/runtime/errbit.rb ${DEPLOYDIR}/current/config/initializers/ \
 && ln -s ${DEPLOYDIR}/shared/screenshots ${DEPLOYDIR}/current/public/screenshots \
 && ln -s ${DEPLOYDIR}/shared/cache ${DEPLOYDIR}/current/public/cache


#
# RUNTIME ELEMENTS
# expose, cmd

USER root
ONBUILD EXPOSE 80
WORKDIR ${DEPLOYDIR}/current
CMD ["/opt/bin/start.sh"]
