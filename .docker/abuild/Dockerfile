ARG IMAGE_TAG=3.7
FROM alpine:$IMAGE_TAG

ARG IMAGE_TAG=3.7
ENV GIT_DISCOVERY_ACROSS_FILESYSTEM=1
ENV IMAGE_TAG=$IMAGE_TAG

COPY . /

RUN apk add --no-cache alpine-sdk sudo \
    && adduser -D -g '' -u 1000 -G abuild packager \
    && echo "packager ALL=(ALL) ALL" >> /etc/sudoers \
    && echo "packager ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && echo "/public/v${IMAGE_TAG}" | tee -a /etc/apk/repositories \
    && mkdir -p /home/packager/.abuild \
    && ln -s /build/dobrevit.rsa.priv /home/packager/.abuild/dobrevit.rsa.priv \
    && chmod 775 /home/packager \
    && chown packager:abuild /home/packager \
    && chown packager:abuild /home/packager/.abuild \
    && ln -s /public/dobrevit.rsa.pub /etc/apk/keys/dobrevit.rsa.pub \
    # For building some packages (litespeeed and pear) the php command is used
    # and we'll use the latest development php.ini files to show possible warnings
    # and notices
    && mkdir -p /etc/php/5.6 /etc/php/7.0 /etc/php/7.1 /etc/php/7.2 /etc/php/7.3 /etc/php/7.4 \
    && curl https://raw.githubusercontent.com/php/php-src/PHP-5.6/php.ini-development --output /etc/php/5.6/php.ini \
    && curl https://raw.githubusercontent.com/php/php-src/PHP-7.0/php.ini-development --output /etc/php/7.0/php.ini \
    && curl https://raw.githubusercontent.com/php/php-src/PHP-7.1/php.ini-development --output /etc/php/7.1/php.ini \
    && curl https://raw.githubusercontent.com/php/php-src/PHP-7.2/php.ini-development --output /etc/php/7.2/php.ini \
    && curl https://raw.githubusercontent.com/php/php-src/PHP-7.3/php.ini-development --output /etc/php/7.3/php.ini \
    && curl https://raw.githubusercontent.com/php/php-src/PHP-7.4/php.ini-development --output /etc/php/7.4/php.ini

USER packager

WORKDIR /build
