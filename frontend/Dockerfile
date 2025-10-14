FROM node:22-alpine AS build
WORKDIR /app

ENV VITE_API_BASE_URL=__API_BASE_URL__

ENV CI=true
COPY package.json package-lock.json* ./
RUN npm ci --no-audit --no-fund

COPY . .
RUN npm run build

FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=build /app/dist /usr/share/nginx/html

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]