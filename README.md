# AlertHawk.Mobile

Mobile version of AlertHawk - Real-time monitoring dashboard application.

[![Build status](https://dev.azure.com/thiagoguaru/AlertHawk/_apis/build/status/AlertHawk%20-%20Mobile%20Android)](https://dev.azure.com/thiagoguaru/AlertHawk/_build/latest?definitionId=31)
[![Build status](https://dev.azure.com/thiagoguaru/AlertHawk/_apis/build/status/AlertHawk%20-%20Mobile%20iOS)](https://dev.azure.com/thiagoguaru/AlertHawk/_build/latest?definitionId=30)

## Overview

AlertHawk Mobile provides real-time monitoring of your services across different environments. Track uptime, response times, and receive instant alerts when issues occur.

## Features

### Monitor Dashboard
- Real-time status monitoring (Up/Down/Paused)
- Group-based organization
- Environment-specific views (Production, Staging, QA, etc.)
- Quick uptime statistics (1h, 24h, 7d)
- Search and filter capabilities

### Monitor Details
- Interactive response time charts
- SSL certificate expiration monitoring
- Comprehensive uptime statistics
- Visual failure indicators
- Historical performance data

### Alerts
- Real-time alert notifications
- Historical alert viewing
- Name-based filtering
- Configurable time ranges (1-180 days)
- Environment-specific alert views

## Getting Started

### Prerequisites
- Flutter SDK (^3.6.0)
- Dart SDK (^3.6.0)
- Running instance of AlertHawk backend services

### Configuration

Create a `.env` file in the project root with the following settings:
```
MONITORING_API_URL=https://monitoring.alerthawk.net
AUTH_API_URL=https://auth.alerthawk.net/api
NOTIFICATION_API_URL=https://notification.alerthawk.net/api
AZURE_AD_TENANT=your-tenant-id
AZURE_AD_CLIENT_ID=your-client-id
AUTH_API_KEY=your-auth-api-key```

## Authentication

The app supports two authentication methods:
1. Username/Password authentication
2. Microsoft Azure AD (configurable in settings)

## Settings

Configure the following through the app:
- API endpoints (Monitoring, Auth, Notification)
- Authentication settings
- Azure AD configuration
- API keys

## Building

The project includes Azure DevOps pipelines for both Android and iOS builds. Build status is indicated by the badges above.

### Platform Support
- iOS
- Android
- macOS
- Windows (coming soon)
- Linux (coming soon)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Support

For issues and feature requests:
- Create an issue in the repository
- Contact the development team

## License

This project is licensed under the MIT License - see the LICENSE file for details.