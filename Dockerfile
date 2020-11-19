ARG NODE_VERSION=12.10.0
FROM node:${NODE_VERSION}

# Add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added.
RUN groupadd --system nightmare && useradd --system --create-home --gid nightmare nightmare

RUN apt-get update && \
      apt-get install -y libgtk2.0-0 libgconf-2-4 \
      libasound2 libxtst6 libxss1 libnss3 xvfb libfontconfig1

# Install latest chrome dev package.
# Note: this installs the necessary libs to make the bundled version of Chromium that Puppeteer
# installs, work.
RUN apt-get update && apt-get install -y wget --no-install-recommends \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-unstable \
      --no-install-recommends \
    && apt-get install -y libgbm1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge --auto-remove -y curl \
    && rm -rf /src/*.deb


# Add pptr user.
RUN groupadd -r pptruser && useradd -r -g pptruser -G audio,video pptruser \
    && mkdir -p /home/pptruser/Downloads \
    && chown -R pptruser:pptruser /home/pptruser \
    && chown -R pptruser:pptruser /home/pptruser


COPY . /tests

RUN chown -R pptruser:pptruser /tests
RUN runuser -l pptruser -c 'npm install --loglevel=warn --prefix /tests'

WORKDIR /tests

RUN runuser -l pptruser -c 'yarn'
#RUN ln -s /tests/node_modules/.bin/codeceptjs /usr/local/bin/codeceptjs
ENV PATH /tests/node_modules/.bin:$PATH

# Set HOST ENV variable for Selenium Server
ENV HOST=selenium

# Set the entrypoint for Nightmare
#ENTRYPOINT ["/tests/entrypoint"]