FROM oven/bun:1-alpine AS builder
WORKDIR /app
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile

ARG VITE_PORTAL_URL=https://kombify.io
ARG VITE_KOMBISTACK_URL=https://stack.kombify.io
ARG VITE_KOMBISIM_URL=https://simulate.kombify.io
ENV VITE_PORTAL_URL=$VITE_PORTAL_URL
ENV VITE_KOMBISTACK_URL=$VITE_KOMBISTACK_URL
ENV VITE_KOMBISIM_URL=$VITE_KOMBISIM_URL

COPY . .
RUN bun run build

FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
