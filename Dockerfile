FROM node:latest

MAINTAINER Gordon Thomson <gordon@sumacmentoring.co.uk>

USER root

RUN apt-get update && apt install -y ca-certificates apt-transport-https && wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - && echo "deb https://packages.sury.org/php/ jessie main" | tee /etc/apt/sources.list.d/php.list && apt-get update && apt-get upgrade -y && apt install -y \
        git doxygen vim python python-dev ca-certificates dialog gcc musl-dev \
        libffi-dev zip unzip curl autoconf automake re2c tzdata libxml2 libxml2-dev \
        bison openssl gettext libmcrypt-dev xvfb \
        mysql-client \
        php7.2 \
        php7.2-bcmath \
        php7.2-cgi \
        php7.2-cli \
        php7.2-common \
        php7.2-curl \
        php7.2-dev \
        php7.2-dba \
        php7.2-fpm \
        php7.2-imap \
        php7.2-json \
        php7.2-mbstring \
        php7.2-mysql \
        php7.2-opcache \
        php7.2-readline \
        php7.2-soap \
        php7.2-sqlite3 \
        php7.2-xml \
        php7.2-zip

# Install php tools
RUN mkdir -p /usr/local/bin
RUN wget -q -O /usr/local/bin/phpunit https://phar.phpunit.de/phpunit.phar && chmod +x /usr/local/bin/phpunit
RUN wget -q -O /usr/local/bin/phpcov https://phar.phpunit.de/phpcov.phar && chmod +x /usr/local/bin/phpcov
RUN wget -q -O /usr/local/bin/phpcpd https://phar.phpunit.de/phpcpd.phar && chmod +x /usr/local/bin/phpcpd
RUN wget -q -O /usr/local/bin/phploc https://phar.phpunit.de/phploc.phar && chmod +x /usr/local/bin/phploc
RUN wget -q -O /usr/local/bin/phptok https://phar.phpunit.de/phptok.phar && chmod +x /usr/local/bin/phptok
RUN wget -q -O /usr/local/bin/composer https://getcomposer.org/composer.phar && chmod +x /usr/local/bin/composer
RUN wget -q -O /usr/local/bin/phpmd http://static.phpmd.org/php/latest/phpmd.phar && chmod +x /usr/local/bin/phpmd
RUN wget -q -O /usr/local/bin/sami http://get.sensiolabs.org/sami.phar && chmod +x /usr/local/bin/sami
RUN wget -q -O /usr/local/bin/phpcbf https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar && chmod +x /usr/local/bin/phpcbf
RUN wget -q -O /usr/local/bin/phpcs https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar && chmod +x /usr/local/bin/phpcs
RUN wget -q -O /usr/local/bin/phpdox http://phpdox.de/releases/phpdox.phar && chmod +x /usr/local/bin/phpdox
RUN wget -q -O /usr/local/bin/pdepend http://static.pdepend.org/php/latest/pdepend.phar && chmod +x /usr/local/bin/pdepend
RUN wget -q -O /usr/local/bin/phpbrew https://github.com/phpbrew/phpbrew/raw/master/phpbrew && chmod +x /usr/local/bin/phpbrew

# Clean packages
RUN rm -rf /var/cache/apk/*

EXPOSE 3000

ENV STRIDER_VERSION=v1.10.0 STRIDER_GIT_SRC=https://github.com/Strider-CD/strider.git STRIDER_HOME=/data STRIDER_SRC=/opt/strider
ENV NODE_ENV production

RUN useradd --comment "Strider CD" --home ${STRIDER_HOME} strider && mkdir -p ${STRIDER_HOME} && chown strider:strider ${STRIDER_HOME}
VOLUME [ "$STRIDER_HOME" ]

RUN mkdir -p $STRIDER_SRC && cd $STRIDER_SRC && \
    # Checkout into $STRIDER_SRC
    git clone $STRIDER_GIT_SRC . && \
    [ "$STRIDER_VERSION" != 'master' ] && git checkout tags/$STRIDER_VERSION || git checkout master && \
    rm -rf .git && \
    # Install NPM deps
    npm install && \
    # FIX: https://github.com/Strider-CD/strider/pull/1056
    npm install morgan@1.5.0 &&\
    # Create link to strider home dir so the modules can be used as a cache
    mv node_modules node_modules.cache && ln -s ${STRIDER_HOME}/node_modules node_modules && \
    # Allow strider user to update .restart file
    chown strider:strider ${STRIDER_SRC}/.restart && \
    # Cleanup Upstream cruft
    rm -rf /tmp/*

ENV PATH ${STRIDER_SRC}/bin:$PATH

COPY entry.sh /
RUN chown strider:strider entry.sh
RUN chmod 755 entry.sh
USER strider
ENTRYPOINT ["/entry.sh"]
CMD ["strider"]
