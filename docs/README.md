# DbxSmith Documentation Site

This directory contains the source code for the DbxSmith documentation and blog, built using [Docusaurus 3](https://docusaurus.io/).

## 🛠️ Local Development

### Prerequisites
- **Node.js**: >= 20.0 (Matches CI environment)
- **npm**: Standard with Node.js

### Commands
```bash
# Install dependencies
npm install

# Start the development server
npm start
```
By default, the site will be served at `http://localhost:3000/dbx-smith/`.

## 📁 File Structure
- `docs/`: Markdown files for the technical documentation.
- `blog/`: Markdown files for the announcement and update posts.
- `src/`: Custom React components and styling.
- `static/`: Images, icons, and other static assets.

## 📊 Features
- **Mermaid Diagrams**: We have built-in support for Mermaid. Use ` ```mermaid ` code blocks in your markdown.
- **Search**: Fully searchable content (once indexed by search engines).
- **Responsive Design**: Optimized for mobile and desktop viewing.

## 🚀 Build & Deployment
The build process generates a static `build/` directory:
```bash
npm run build
```

**Automated Deployment**:
You do not need to deploy manually. The [`.github/workflows/deploy-docs.yml`](../.github/workflows/deploy-docs.yml) workflow automatically:
1. Triggers on any push to `main` that modifies the `docs/` folder.
2. Builds the site using Node 20.
3. Deploys the result to the `gh-pages` branch.
