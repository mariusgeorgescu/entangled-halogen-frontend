# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Migrated to external `purescript-cardano-capabilities` library from GitHub
- Migrated to external `purescript-halogen-daisyui` library 
- Updated to use latest `halogen-cardano-wallet-connect-component` from GitHub
- Simplified capability instance declarations (empty marker instances instead of verbose implementations)
- Updated imports to use `Cardano.Capabilities` modules instead of local `Capabilities` modules
- Updated wallet connect component import from `WalletConnect.Component` to `Components.WalletConnectComponent`
- Refactored `App.Utils` to only export used functions (`lovelaceToAda`, `scrollToTop`)
- Refactored `Components.HTML.RenderUtils.App` to use library components and keep only app-specific sections
- BFF configuration now requires all environment variables (no default values)
- Environment variable validation with error messages on startup if values are missing
- Replaced `Test.Unit.Console` with proper `Effect.Console` for runtime logging

### Added
- SEO meta tags (title, description, keywords, author)
- Open Graph meta tags for Facebook/LinkedIn sharing with brand cover images
- Twitter Card meta tags for Twitter/X sharing with brand header images
- Apple touch icon for iOS home screen
- Theme color meta tag for mobile browser UI
- New `purescript-halogen-daisyui` library with reusable daisyUI components:
  - Buttons (primary, secondary, accent)
  - Loading indicators (spinners, bars)
  - Tooltips (all positions)
  - Toasts (with icons)
  - Modals
  - Dividers (horizontal, vertical)
  - Stats
  - Tables
  - Cards (with image overlays)
  - Carousels and hover galleries
  - Accordions
  - Links
  - Footer helpers
  - Filters
  - Text rotation animations
- Utility functions in library: string manipulation, number formatting, date formatting, array helpers, DOM scroll operations
- Form field types compatible with halogen-formless
- Support for API key authentication in proxy routes (in addition to Basic Auth)
- Integrated gomaestro-api service into proxy system with API key authentication
- Environment variable logging at server startup for debugging purposes

### Removed
- Local `MonadInteraction` and `MonadCardanoQuery` capability implementations
- Manual `MonadCIP30` instance implementation (now automatically provided by library)
- Duplicate utility functions (now in halogen-daisyui library)
- Duplicate component implementations (now in halogen-daisyui library)
- Default fallback values for environment variables in BFF config
- Manual `/api/pool-info/:poolId` endpoint (now handled by proxy system)
- Unused form utilities (`withLabel`, `textInput`, `textarea`, `checkbox`, `swap`, `filter`)
- Unused `Icons.purs` module (icons now in library or inlined)
- `halogen-formless` dependency (no longer needed)
- Redundant favicon links in index.html (5 → 3)

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
