FROM alpine:latest

COPY script.sh /script.sh

# Make the script executable
RUN chmod +x /script.sh

# Install packages
RUN apk add --no-cache bash curl jq

# Add the cron job
RUN echo "*/5 * * * * /bin/bash /script.sh >> /var/log/cron.log 2>&1" | crontab -

# Start cron in the foreground
CMD ["crond", "-f"]
