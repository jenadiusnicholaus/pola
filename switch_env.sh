#!/bin/bash

# Environment Switcher Script for Pola App
# Usage: ./switch_env.sh [development|staging|production]

ENV=$1

if [ -z "$ENV" ]; then
    echo "❌ Error: No environment specified"
    echo "Usage: ./switch_env.sh [development|staging|production]"
    echo ""
    echo "Available environments:"
    echo "  - development  (Local: http://192.168.1.181:8000)"
    echo "  - staging      (Live Test: http://185.237.253.223:8086)"
    echo "  - production   (Production server)"
    exit 1
fi

case $ENV in
    development)
        echo "🔄 Switching to DEVELOPMENT environment..."
        cp .env.development .env
        echo "✅ Successfully switched to DEVELOPMENT"
        echo "📍 API URL: http://192.168.1.181:8000"
        ;;
    staging)
        echo "🔄 Switching to STAGING environment..."
        cp .env.staging .env
        echo "✅ Successfully switched to STAGING (Live Test Server)"
        echo "📍 API URL: http://185.237.253.223:8086"
        ;;
    production)
        echo "🔄 Switching to PRODUCTION environment..."
        echo "⚠️  WARNING: You are switching to PRODUCTION!"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            cp .env.production .env
            echo "✅ Successfully switched to PRODUCTION"
            echo "📍 API URL: Production server"
        else
            echo "❌ Cancelled"
            exit 1
        fi
        ;;
    *)
        echo "❌ Error: Invalid environment '$ENV'"
        echo "Valid options: development, staging, production"
        exit 1
        ;;
esac

echo ""
echo "🔁 Run 'flutter clean && flutter pub get' to apply changes"
