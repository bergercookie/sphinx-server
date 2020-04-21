FROM python:3.8.0-alpine3.10

MAINTAINER Loïc Pauletto <loic.pauletto@gmail.com>
MAINTAINER Quentin de Longraye <quentin@dldl.fr>

COPY ./requirements.txt requirements.txt

RUN apk add --no-cache --virtual --update py3-pip make wget ca-certificates ttf-dejavu openjdk8-jre graphviz sudo \
    && pip install --upgrade pip \
    && pip install --no-cache-dir  -r requirements.txt

RUN wget http://downloads.sourceforge.net/project/plantuml/plantuml.jar -P /opt/ \
    && echo -e '#!/bin/sh -e\njava -jar /opt/plantuml.jar "$@"' > /usr/local/bin/plantuml \
    && chmod +x /usr/local/bin/plantuml

COPY ./server.py /opt/sphinx-server/
COPY ./.sphinx-server.yml /opt/sphinx-server/

# install spellchecking tools
RUN apk add --update enchant-dev aspell-en

# cpython is broken on alpine - find the library manually - https://github.com/docker-library/python/issues/111
ENV PYENCHANT_LIBRARY_PATH "/usr/lib/libenchant.so"

# run as a normal user ------------------------------------------------------------------------
ARG USR=developer
ARG UID=1000
ARG GID=1000
ARG HOME=/web
RUN mkdir -p $HOME
RUN echo "$USR:x:$UID:$GID:$USR,,,:$HOME:/bin/sh" >> /etc/passwd
RUN echo "$USR:x:$UID:" >> /etc/group
RUN echo "$USR ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USR
RUN chmod 0440 /etc/sudoers.d/$USR
RUN chown $UID:$GID -R $HOME
USER $USR
ENV HOME $HOME
WORKDIR $HOME

RUN sudo chown -R $USR:$USR /opt/sphinx-server

EXPOSE 8000 35729

CMD ["python", "/opt/sphinx-server/server.py"]
