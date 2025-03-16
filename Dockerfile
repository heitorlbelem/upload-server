# STAGE 1: ARTIFACT PNPM
FROM node:20.18 AS base
RUN npm i -g pnpm

# STAGE 2: ARTIFACT DEPENDENCIES (NODE_MODULES)
FROM base as dependencies
WORKDIR /usr/src/app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# STAGE 3: ARTIFACT BUILD (DIST)
FROM base AS build
WORKDIR /usr/src/app
COPY . .
COPY --from=dependencies /usr/src/app/node_modules ./node_modules
RUN pnpm build
RUN pnpm prune --prod

# STAGE 4: FINAL IMAGE
FROM gcr.io/distroless/nodejs20-debian12 AS release
USER 1000
WORKDIR /usr/src/app
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json

EXPOSE 3333
CMD ["dist/infra/http/server.js"]
