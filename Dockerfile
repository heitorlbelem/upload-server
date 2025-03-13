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

ENV DATABASE_URL="postgresql://docker:docker@localhost:5432/upload_test"
ENV CLOUDFLARE_ACCOUNT_ID=""
ENV CLOUDFLARE_ACCESS_KEY_ID=""
ENV CLOUDFLARE_SECRET_ACCESS_KEY=""
ENV CLOUDFLARE_BUCKET="upload-server"
ENV CLOUDFLARE_PUBLIC_URL="https://pub-21179408124e469bbce0f7b0981a32fa.r2.dev"

EXPOSE 3333
CMD ["dist/infra/http/server.js"]
