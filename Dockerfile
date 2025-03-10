FROM node:20.18

RUN npm i -g pnpm

WORKDIR /usr/src/app

COPY package.json pnpm-lock.yaml ./

RUN pnpm install

COPY . .

RUN pnpm build

RUN pnpm prune --prod

ENV DATABASE_URL="postgresql://docker:docker@localhost:5432/upload_test"
ENV CLOUDFLARE_ACCOUNT_ID=""
ENV CLOUDFLARE_ACCESS_KEY_ID=""
ENV CLOUDFLARE_SECRET_ACCESS_KEY=""
ENV CLOUDFLARE_BUCKET="upload-server"
ENV CLOUDFLARE_PUBLIC_URL="https://pub-21179408124e469bbce0f7b0981a32fa.r2.dev"

EXPOSE 3333

CMD ["pnpm", "start"]
