# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- BFF configuration now requires all environment variables (no default values)
- Environment variable validation with error messages on startup if values are missing
- Added environment variable debugging output at startup (sensitive values are masked)

### Added
- Support for API key authentication in proxy routes (in addition to Basic Auth)
- Integrated gomaestro-api service into proxy system with API key authentication
- Environment variable logging at server startup for debugging purposes

### Removed
- Default fallback values for environment variables in BFF config
- Manual `/api/pool-info/:poolId` endpoint (now handled by proxy system)

## [0.2.0] - 2024-12-19

### Added
- Mobile-friendly responsive design across all pages
- Viewport meta tag for proper mobile rendering
- Responsive navigation bar with adaptive logo and button sizes
- Mobile-optimized hero section with stacked buttons on small screens
- Responsive footer that switches from vertical to horizontal layout
- Mobile-friendly button layouts that stack vertically on small screens

### Changed
- Updated all sections with responsive padding and spacing (`px-4 sm:px-6`, `py-8 sm:py-12`)
- Made text sizes responsive throughout the application
- Buttons now use full-width on mobile and auto-width on larger screens
- Footer layout changes from vertical to horizontal based on screen size
- Logo gallery and images now scale appropriately on mobile devices
- Improved touch targets and spacing for mobile users

### Technical Details
- Implemented Tailwind CSS responsive utilities (`sm:`, `md:`, `lg:` breakpoints)
- Followed daisyUI 5 best practices for responsive design
- All components now use responsive class names for optimal mobile experience

## [0.1.0] - Initial Release

### Added
- Initial project setup
- Home page with hero section
- Professional services section
- Pool overview section
- Security audits portfolio page
- Wallet connection functionality
- Navigation bar component
