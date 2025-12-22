# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2024-12-22

### Added
- Real-time pool information integration with Gomaestro API
- New `MonadCardanoQuery` capability for Cardano blockchain queries
- Dynamic pool stats display showing all available metrics (margin, pledge, fixed cost, live stake, active stake, delegators, blocks, saturation, pool name, ticker)
- BFF endpoint `/api/pool-info/:poolId` for proxying pool information requests
- Environment variable `GOMAESTRO_API_KEY` support in BFF configuration

### Changed
- Pool overview section now fetches and displays real-time data from Gomaestro API
- `fetchPoolInfo` now accepts `poolId` as a parameter for flexible pool queries
- Moved `PoolInfo` type and related types to `MonadCardanoQuery` capability module
- Renamed `PoolInfoResponse` to `PoolInfoMaestroResponse` for clarity
- Pool stats display dynamically shows all available fields, hiding missing data gracefully
- Improved number formatting with proper ADA (₳) symbol and K/M suffixes

### Technical Details
- Created `MonadCardanoQuery` type class following PureScript capability pattern
- Implemented custom JSON decoder for nested Gomaestro API response structure
- Added proper type definitions for `PoolInfo`, `PoolMetaJson`, `PoolData`, and `PoolInfoMaestroResponse`
- All pool-related types and operations are now co-located in the capability module
- Maintains backward compatibility with fallback to static stats when API data is unavailable

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
