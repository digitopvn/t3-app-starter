# ===================================
#       PHASE 1 - BUILDER
# ===================================

FROM node:18 AS BUILD_IMAGE

ENV NODE_OPTIONS=--max_old_space_size=8192

WORKDIR /usr/src

COPY ./package.json ./package.json

RUN npm i pnpm -g

# apps
COPY . .
COPY ./.env.prod ./.env

# Start building
RUN npm run build

# install node-prune (https://github.com/tj/node-prune)
RUN curl -sf https://gobinaries.com/tj/node-prune | sh

# run node-prune to scan for other unused node_modules packages
RUN /usr/local/bin/node-prune

# ===================================
#       PHASE 2 - RUNNER
# ===================================

FROM node:18-alpine AS RUNNER

# Don't run production as root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

WORKDIR /usr/app

# Only copy build files & neccessary files to run:
COPY --from=BUILD_IMAGE --chown=nextjs:nodejs /usr/src/next.config.mjs .
COPY --from=BUILD_IMAGE --chown=nextjs:nodejs /usr/src/.next/standalone .
COPY --from=BUILD_IMAGE --chown=nextjs:nodejs /usr/src/.next/static ./.next/static
COPY --from=BUILD_IMAGE --chown=nextjs:nodejs /usr/src/public ./public
COPY --from=BUILD_IMAGE --chown=nextjs:nodejs /usr/src/node_modules ./node_modules
# COPY --from=BUILD_IMAGE --chown=nextjs:nodejs /usr/src/next-i18next.config.js .
COPY --from=BUILD_IMAGE --chown=nextjs:nodejs /usr/src/.env .

EXPOSE 3000 80

CMD npm run start