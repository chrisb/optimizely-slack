# Optimizely -> Slack

This script will dump Optimizely experiment metrics to a Slack channel of your choosing. It looks for any running experiment and will show results against the primary metric.

## Setup

Install gem dependencies:

```bash
bundle
```

Copy the sample `.env`:

```bash
cp .env.example .env
```

Now, edit `.env` with your credentials.

## Usage

After configuring the credentials above, run:

```bash
rake
```
