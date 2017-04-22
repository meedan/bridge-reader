# bridge-reader

FROM dreg.meedan.net/meedan/ruby
MAINTAINER sysops@meedan.com

ENV IMAGE=dreg.meedan.net/bridge/reader \
    DEPLOYUSER=bridgereader \
    DEPLOYDIR=/app \
    RAILS_ENV=production \
    GITREPO=git@github.com:meedan/check-api.git \
    PRODUCT=bridge \
    APP=bridge-reader \
    TERM=xterm \
    MIN_INSTANCES=4 \
    MAX_POOL_SIZE=12

# ENV GITREPO=git@github-bridgreader:meedan/bridge-reader.git

COPY ./docker/bin/* /opt/bin/
RUN chmod 755 /opt/bin/*.sh

RUN apt-get install -y imagemagick fonts-arphic-ukai fonts-arphic-uming fonts-ipafont-mincho fonts-ipafont-gothic fonts-unfonts-core

#
# APP CONFIG
#

# nginx for bridge-reader
RUN rm /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
COPY ./docker/config/nginx/bridge-reader /etc/nginx/sites-enabled/bridge-reader

#
# USER CONFIG
#

RUN useradd ${DEPLOYUSER} -s /bin/bash -m

#
# code deployment
#

RUN mkdir -p $DEPLOYDIR/latest \
    && chown -R ${DEPLOYUSER}:www-data ${DEPLOYDIR}

USER ${DEPLOYUSER}
WORKDIR ${DEPLOYDIR}
# install the gems first so that we can more easily cache them and allow code changes to be made later
COPY ./Gemfile ./latest/Gemfile
COPY ./Gemfile.lock ./latest/Gemfile.lock
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc \
    && cd ./latest \
    && bundle install  --jobs 20 --retry 5 --deployment --without test development

COPY . ./latest
USER root
RUN chown -R ${DEPLOYUSER}:www-data ${DEPLOYDIR}
USER ${DEPLOYUSER}

RUN /opt/bin/find_and_link_config_files.sh ${DEPLOYDIR}/latest
RUN mv ./latest ./bridge-reader-$(date -I) \
    && ln -s ./bridge-reader-$(date -I) ./current

RUN rm -rf ${DEPLOYDIR}/current/config/projects \
    && ln -s ${DEPLOYDIR}/shared/projects ${DEPLOYDIR}/current/config/ \
    && ln -s ${DEPLOYDIR}/shared/screenshots ${DEPLOYDIR}/current/public/screenshots \
    && ln -s ${DEPLOYDIR}/shared/cache ${DEPLOYDIR}/current/public/cache

#
# RUNTIME ELEMENTS
# expose, cmd

USER root
ONBUILD EXPOSE 80
WORKDIR ${DEPLOYDIR}/current
CMD ["/opt/bin/start.sh"]
