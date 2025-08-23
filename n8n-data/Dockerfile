FROM n8nio/n8n:latest

USER root

# Install Chromium and dependencies
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    npm

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

USER node

# Install puppeteer-extra and plugins in n8n-nodes-puppeteer directory (where your custom node code is)
RUN mkdir -p /home/node/.n8n/nodes/node_modules/n8n-nodes-puppeteer && \
    cd /home/node/.n8n/nodes/node_modules/n8n-nodes-puppeteer && \
    npm install puppeteer-extra puppeteer-extra-plugin-stealth puppeteer-extra-plugin-user-preferences
