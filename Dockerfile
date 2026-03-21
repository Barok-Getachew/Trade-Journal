# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release --no-tree-shake-icons

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy the build output from the build stage
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copy the Nginx configuration template
COPY nginx.conf /etc/nginx/conf.d/config.template

# Install gettext for envsubst
RUN apk add --no-cache gettext

# Use envsubst to replace $PORT and start Nginx
CMD envsubst '$PORT' < /etc/nginx/conf.d/config.template > /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'
