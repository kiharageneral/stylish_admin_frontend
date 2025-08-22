# Full-Stack E-commerce & AI Chat Platform (Django + Flutter)

This repository contains the official source code for the Udemy course building a complete, production-grade e-commerce platform with a Flutter admin dashboard and an integrated AI-powered chat agent. The project is divided between a `backend` directory (Django) and a `frontend` directory (Flutter).

## About This Project

This is not just a demo application. We build a comprehensive, real-world system from the ground up, focusing on clean architecture, scalability, and modern development practices. By the end of the course, you will have built:

* A **secure, token-based REST API** using Django REST Framework.
* A **responsive admin dashboard** using Flutter, BLoC, and Clean Architecture.
* A complete **e-commerce backend** with products, variants, inventory, and orders.
* An **intelligent, LLM-powered chat agent** capable of performing tasks and providing insights.

## How to Use This Repository

The code is structured using Git tags that correspond to the major sections of the course. This allows you to check out the exact state of the project at the end of each key milestone.

**1. Clone the repository:**
```bash
git clone <your-repository-url>
cd <your-repository-folder>
```

**2. List all available tags:**
```bash
git tag
```
This will show you `v2.3`, `v4.0`, and `v5.0`.

**3. Check out the code for a specific section:**
Use the tag corresponding to the section you've just completed. For example, after finishing Section 3, use:
```bash
git checkout v2.3
```

### Course Section and Tag Mapping

| Tag | Corresponding Course Section(s) Completed | Description |
| :-- | :--- | :--- |
| `v2.3` | **Section 2 & 3** | The complete backend and frontend for the core **Authentication System**. |
| `v4.0` | **Section 4** | The complete backend and frontend for the **E-commerce Platform**. |
| `v5.0` | **Section 5** | The complete backend and frontend for the **AI-Powered Agents & Chat**. |

**Note**: The `v5.0` tag also includes the necessary seed files that will be used in Section 6.

## Technology Stack & Key Features

### Backend (Django)
- **Framework**: Django & Django REST Framework
- **Authentication**: JWT-based with Refresh/Access tokens
- **Asynchronous Tasks**: Celery with Redis for background tasks like sending emails
- **Database**: PostgreSQL for production-ready data persistence
- **Caching**: Redis for advanced caching strategies to improve performance
- **AI Agents**: Custom framework for building intelligent LLM-powered agents (MCP)
- **API Safety**: Rate limiting and a circuit breaker pattern
- **Core Features**: Custom user model, standardized API responses, environment variable management, and a robust services layer.

### Frontend (Flutter)
- **Architecture**: Clean Architecture
- **State Management**: BLoC for predictable and scalable state
- **Routing**: GoRouter for advanced navigation
- **Dependency Injection**: `get_it` for managing dependencies
- **Networking**: `Dio` with interceptors for token management
- **UI**: Responsive design for various screen sizes, custom theming, and a feature-rich interface for managing products, variants, and AI chat.
- **Global State**: An event bus for cross-feature communication.

## Prerequisites & Setup

All environment setup and configuration are covered in detail in **Section 1: Getting Started** of the course. Before running the code, ensure you have completed that section and have the following installed:
* Python & Django
* Flutter SDK
* Git
* VS Code (or your preferred editor)
* Postman (for API testing)

## Found an Issue?

If you find a bug or have a suggestion, please open an issue on this repository. This is the best way to track and resolve problems.
