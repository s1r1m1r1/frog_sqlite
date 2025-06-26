# Specify the Dart SDK base image version using dart:<version> (ex: dart:2.12)
FROM dart:stable AS build

# Resolve app dependencies
WORKDIR /app
COPY pubspec.* ./
# Use ./ for consistency with WORKDIR
RUN dart pub get

# Copy app source code and AOT compile it
COPY . .

# Generate a production build for Dart Frog
RUN dart pub global activate dart_frog_cli
RUN dart pub global run dart_frog_cli:dart_frog build

# Ensure packages are still up-to-date if anything has changed (for the build output)
RUN dart pub get --offline

# AOT compile the Dart Frog server executable
# The output path should match where dart_frog build places the server entry point
RUN dart compile exe build/bin/server.dart -o build/bin/server

# Stage to get the libsqlite3.so.0 library
FROM debian:bullseye-slim AS sqlite_source

# Install libsqlite3-0 which contains the libsqlite3.so.0 shared library
# --no-install-recommends helps keep the image small
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libsqlite3-0 && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* # Clean up apt cache

# --- FINAL RUNTIME IMAGE ---
# Use debian:bullseye-slim as the final base image.
# It's slightly larger than distroless, but provides a full and consistent
# glibc environment, crucially including /bin/sh to create the symlink.
FROM debian:bullseye-slim

# Copy Dart runtime and your compiled application from the build stage
COPY --from=build /runtime/ /
COPY --from=build /app/build/bin/server /app/bin/server

# Copy the specific libsqlite3.so.0 from the 'sqlite_source' stage
# The path is confirmed for aarch64 Debian systems.
COPY --from=sqlite_source /usr/lib/aarch64-linux-gnu/libsqlite3.so.0 /usr/lib/libsqlite3.so.0

# Create the generic symlink for libsqlite3.so
# This RUN command will now work because debian:bullseye-slim has /bin/sh
RUN ln -s /usr/lib/libsqlite3.so.0 /usr/lib/libsqlite3.so

# Start server.
EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]