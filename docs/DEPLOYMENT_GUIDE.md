# Jamf Device Manager - Deployment Guide

## Overview

## System Requirements

- **Operating System**: macOS 13.0 or later
- **RAM**: 8 GB minimum
- **Storage**: 50 MB available disk space
- **Network**: Internet connection to Jamf Pro server

## Jamf Pro API Setup

### Create API Role
1. Log in to Jamf Pro Admin Console
2. Navigate to **Settings** > **System** > **API Roles and Clients**
3. Click **New** under API Roles
4. Name: `Jamf Device Manager Role`
5. Add privileges:
Read Computer Check-in
Update Computers
Read Computers
Update User
Create Computers
Send Computer Remote Lock Command
Send Computer Unmanage Comman

### Create API Client
1. Click **New** under API Clients
2. **Display Name**: `Jamf Device Manager Client`
3. **Access Token Lifetime**: 30 minutes
4. **API Role**: Select the role created above
5. **Enabled**: ✅ Checked
6. Save and note the **Client ID** and **Client Secret**