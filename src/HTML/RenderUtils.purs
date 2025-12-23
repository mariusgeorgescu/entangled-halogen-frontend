module Components.HTML.RenderUtils.App
  ( -- Re-export library components  
    module Halogen.DaisyUI.Components
  -- App-specific sections
  , renderProfessionalServicesSection
  , renderHeroSection
  , renderPoolOverviewSection
  , renderFooterSection
  , renderFabFlower
  ) where

import Prelude
import App.Utils (lovelaceToAda)
import Cardano.Capabilities (PoolInfo(..))
import Data.Array (mapMaybe, length)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Data.Number (floor)
import Halogen.DaisyUI.Components
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.Svg.Attributes as SA
import Halogen.Svg.Attributes.Color (Color(..))
import Halogen.Svg.Attributes.StrokeLineCap (StrokeLineCap(..))
import Halogen.Svg.Attributes.StrokeLineJoin (StrokeLineJoin(..))
import Halogen.Svg.Elements as SE

-- ==============================================================================
-- PROFESSIONAL SERVICES (App-specific Static Section)
-- ==============================================================================
renderProfessionalServicesSection :: forall w i. Array (HH.HTML w i) -> HH.HTML w i
renderProfessionalServicesSection buttonsList =
  HH.section
    [ HP.id "services"
    , HP.classes [ HH.ClassName "w-full max-w-6xl mx-auto px-4 sm:px-6 py-8 sm:py-12" ]
    ]
    [ HH.div [ HP.classes [ HH.ClassName "text-center mb-6 sm:mb-8" ] ]
        [ HH.h2 [ HP.classes [ HH.ClassName "text-2xl sm:text-3xl md:text-4xl font-bold" ] ] [ HH.text "Professional Services" ]
        , HH.p [ HP.classes [ HH.ClassName "opacity-80 mt-2 text-sm sm:text-base px-2" ] ]
            [ HH.text "We transform blockchain ideas into production-ready solutions. Our team specializes in Cardano development, from smart contracts to full-stack dApps, with security and performance at the core."
            ]
        , HH.div [ HP.classes [ HH.ClassName "flex flex-wrap justify-center gap-2 mt-4" ] ]
            [ badge "badge-info" "Fixed budget"
            , badge "badge-info" "Team augmentation"
            , badge "badge-info" "Time and materials"
            ]
        ]
    , HH.div [ HP.classes [ HH.ClassName "grid grid-cols-1 md:grid-cols-2 gap-4" ] ]
        [ serviceCard "Smart Contracts"
            [ "Battle-tested smart contract development"
            , "NFTs, DeFi, DAOs, and custom solutions"
            , "Optimized for efficiency and cost"
            ]
        , serviceCard "Audits"
            [ "Comprehensive security analysis"
            , "Gas optimization recommendations"
            , "Detailed audit reports with actionable insights"
            ]
        , serviceCard "Backend & Frontend"
            [ "Haskell, PureScript, and modern frameworks"
            , "Web3-native user experiences"
            , "Secure API design and integration"
            ]
        , serviceCard "Infrastructure"
            [ "24/7 monitoring and support"
            , "Cloud-native Kubernetes deployments"
            , "Disaster recovery and backup solutions"
            ]
        ]
    , HH.div [ HP.classes [ HH.ClassName "mt-6 flex flex-col sm:flex-row justify-center gap-2" ] ] buttonsList
    ]
  where
  badge :: forall w' i'. String -> String -> HH.HTML w' i'
  badge cls label' = HH.div [ HP.classes [ HH.ClassName ("badge " <> cls) ] ] [ HH.text label' ]

  serviceCard :: forall w' i'. String -> Array String -> HH.HTML w' i'
  serviceCard title items =
    HH.div [ HP.classes [ HH.ClassName "card bg-base-200 shadow" ] ]
      [ HH.div [ HP.classes [ HH.ClassName "card-body" ] ]
          [ HH.h3 [ HP.classes [ HH.ClassName "card-title text-xl" ] ] [ HH.text title ]
          , HH.ul [ HP.classes [ HH.ClassName "list-disc list-inside opacity-90" ] ]
              (items <#> (\t -> HH.li_ [ HH.text t ]))
          ]
      ]

-- ==============================================================================
-- HERO (App-specific Static Section)
-- ==============================================================================
renderHeroSection :: forall w i. Array (HH.HTML w i) -> HH.HTML w i
renderHeroSection buttonsList =
  HH.section
    [ HP.id "hero"
    , HP.classes [ HH.ClassName "w-full bg-base-200" ]
    ]
    [ HH.div [ HP.classes [ HH.ClassName "hero min-h-svh" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "hero-content flex-col lg:flex-row gap-4 sm:gap-8 px-4 sm:px-6" ] ]
            [ HH.div [ HP.classes [ HH.ClassName "w-full lg:w-auto" ] ]
                [ HH.div_
                    [ renderHover3DCard
                        ( HH.figure [ HP.classes [ HH.ClassName "w-[320px] sm:w-[400px] md:w-[500px] lg:w-[600px] rounded-4xl" ] ]
                            [ HH.img
                                [ HP.src "./images/E7D/SVG Vector Files/Transparent Logo.svg"
                                , HP.alt "ENTANGLED Labs Logo"
                                , HP.classes [ HH.ClassName "w-full h-full" ]
                                ]
                            ]
                        )
                    , HH.h3 [ HP.classes [ HH.ClassName "text-xl sm:text-2xl md:text-3xl font-bold mt-2" ] ]
                        [ HH.span_
                            [ HH.text "We "
                            , renderTextRotate "text-2xl sm:text-3xl md:text-4xl text-success" [ " DESIGN 📐 ", " DEVELOP ⌨️ ", " DEPLOY 🌎 ", " SCALE ⬆️ ", " MAINTAIN 🔧 " ]
                            , HH.text " for you."
                            ]
                        ]
                    ]
                , HH.div_
                    [ HH.h1 [ HP.classes [ HH.ClassName "text-3xl sm:text-4xl md:text-5xl font-bold" ] ] [ HH.text "ENTANGLED Labs" ]
                    , HH.p [ HP.classes [ HH.ClassName "py-2 sm:py-4 opacity-80 text-sm sm:text-base" ] ]
                        [ HH.text "Your trusted Cardano infrastructure & development partner" ]
                    , HH.div [ HP.classes [ HH.ClassName "flex flex-col sm:flex-row gap-2 w-full sm:w-auto" ] ] buttonsList
                    ]
                , HH.div [ HP.classes [ HH.ClassName "flex flex-wrap justify-center gap-2 mt-4" ] ]
                    [ renderHoverGallery
                        [ "./images/logos/Cardano-RGB_Logo-Icon-Black.svg"
                        , "./images/logos/Cardano-RGB_Logo-Icon-White.svg"
                        , "./images/logos/Midnight-RGB_Symbol-White.svg"
                        , "./images/logos/Midnight-RGB_Symbol-Black.svg"
                        , "./images/logos/Cardano-RGB_Logo-Icon-Blue.svg"
                        , "./images/logos/bitcoin-btc-logo.svg"
                        ]
                    ]
                ]
            ]
        ]
    ]

-- ==============================================================================
-- POOL OVERVIEW (App-specific Static Section)
-- ==============================================================================
renderPoolOverviewSection :: forall w i. Maybe PoolInfo -> HH.HTML w i
renderPoolOverviewSection maybePoolInfo =
  let
    maybePoolId = case maybePoolInfo of
      Just (PoolInfo info) -> info.pool_id
      Nothing -> Nothing
  in
    HH.section
      [ HP.id "pool"
      , HP.classes [ HH.ClassName "w-full max-w-6xl mx-auto px-4 sm:px-6 py-8 sm:py-12" ]
      ]
      [ HH.div [ HP.classes [ HH.ClassName "text-center mb-6" ] ]
          [ HH.h2 [ HP.classes [ HH.ClassName "text-2xl sm:text-3xl font-bold" ] ] [ HH.text "Cardano Staking Pool" ]
          , HH.p [ HP.classes [ HH.ClassName "opacity-80 mt-2 text-sm sm:text-base px-2" ] ]
              [ HH.text "Secure, reliable, and community-focused staking. As a single pool operator, we're 100% dedicated to our delegators' success."
              ]
          ]
      , HH.div [ HP.classes [ HH.ClassName "grid grid-cols-1 md:grid-cols-3 gap-4" ] ]
          (extractPoolStats maybePoolInfo)
      , case maybePoolId of
          Just poolId ->
            HH.div [ HP.classes [ HH.ClassName "mt-6 flex flex-col sm:flex-row justify-center gap-2" ] ]
              [ HH.a
                  [ HP.classes [ HH.ClassName "btn btn-primary btn-sm sm:btn-md w-full sm:w-auto" ]
                  , HP.href $ "https://cexplorer.io/pool/" <> poolId
                  , HP.target "_blank"
                  ]
                  [ HH.text "See Pool Performance" ]
              , HH.a
                  [ HP.classes [ HH.ClassName "btn btn-sm sm:btn-md w-full sm:w-auto" ]
                  , HP.href "#hero"
                  ]
                  [ HH.text "Join us" ]
              ]
          Nothing -> HH.text ""
      ]
  where
  stat :: forall w' i'. String -> String -> HH.HTML w' i'
  stat value desc =
    HH.div [ HP.classes [ HH.ClassName "card bg-base-200 shadow-lg hover:shadow-xl transition-shadow" ] ]
      [ HH.div [ HP.classes [ HH.ClassName "card-body items-center text-center" ] ]
          [ HH.div [ HP.classes [ HH.ClassName "text-2xl sm:text-3xl md:text-4xl font-bold" ] ] [ HH.text value ]
          , HH.div [ HP.classes [ HH.ClassName "opacity-80 text-sm sm:text-base" ] ] [ HH.text desc ]
          ]
      ]

  extractPoolStats :: Maybe PoolInfo -> Array (HH.HTML w i)
  extractPoolStats Nothing =
    [ stat "99.9%" "Uptime target"
    , stat "Competitive Fees" "More rewards in your wallet"
    , stat "Secured" "Best practices operations"
    ]

  extractPoolStats (Just (PoolInfo poolInfo)) =
    let
      formatAda :: Maybe Number -> String
      formatAda (Just n)
        | n >= 1_000_000.0 =
          let
            millions = n / 1_000_000.0
          in
            if millions >= 100.0 then
              show (floor millions) <> "M ₳"
            else
              let
                rounded = floor (millions * 10.0) / 10.0
              in
                show rounded <> "M ₳"
        | n >= 1_000.0 =
          let
            thousands = n / 1_000.0
          in
            if thousands >= 100.0 then
              show (floor thousands) <> "K ₳"
            else
              let
                rounded = floor (thousands * 10.0) / 10.0
              in
                show rounded <> "K ₳"
        | otherwise = show (floor n) <> " ₳"

      formatAda Nothing = "—"

      formatPercent :: Maybe Number -> String
      formatPercent (Just n)
        | n >= 1.0 = show (n) <> "%"
        | otherwise =
          let
            rounded = floor (n * 100.0) / 100.0
          in
            show rounded <> "%"

      formatPercent Nothing = "—"

      formatNumber :: Maybe Int -> String
      formatNumber (Just n)
        | n >= 1_000_000 = show (floor (toNumber n / 1_000_000.0)) <> "M"
        | n >= 1_000 = show (floor (toNumber n / 1_000.0)) <> "K"
        | otherwise = show n

      formatNumber Nothing = "—"

      allStats =
        [ case poolInfo.margin of
            Just m -> Just $ stat (formatPercent $ Just (m * 100.0)) "Margin"
            Nothing -> Nothing
        , case poolInfo.pledge of
            Just _ -> Just $ stat (formatAda $ lovelaceToAda <$> poolInfo.pledge) "Pledge"
            Nothing -> Nothing
        , case poolInfo.fixed_cost of
            Just _ -> Just $ stat (formatAda $ lovelaceToAda <$> poolInfo.fixed_cost) "Fixed Cost"
            Nothing -> Nothing
        , case poolInfo.live_stake of
            Just _ -> Just $ stat (formatAda $ lovelaceToAda <$> poolInfo.live_stake) "Live Stake"
            Nothing -> Nothing
        , case poolInfo.active_stake of
            Just _ -> Just $ stat (formatAda $ lovelaceToAda <$> poolInfo.active_stake) "Active Stake"
            Nothing -> Nothing
        , case poolInfo.delegators of
            Just _ -> Just $ stat (formatNumber poolInfo.delegators) "Delegators"
            Nothing -> Nothing
        , case poolInfo.blocks of
            Just _ -> Just $ stat (formatNumber poolInfo.blocks) "Blocks Minted"
            Nothing -> Nothing
        , case poolInfo.saturation of
            Just s -> Just $ stat (formatPercent $ Just (s)) "Saturation"
            Nothing -> Nothing
        , case poolInfo.name of
            Just n -> Just $ stat n "Pool Name"
            Nothing -> Nothing
        , case poolInfo.ticker of
            Just t -> Just $ stat t "Ticker"
            Nothing -> Nothing
        ]

      availableStats = mapMaybe identity allStats
    in
      if length availableStats > 0 then
        availableStats
      else
        [ stat "99.9%" "Uptime target"
        , stat "Competitive Fees" "More rewards in your wallet"
        , stat "Secured" "Best practices operations"
        ]

-- ==============================================================================
-- FOOTER (App-specific Static Section)
-- ==============================================================================
renderFooterSection :: forall w i. HH.HTML w i
renderFooterSection =
  HH.footer [ HP.classes [ HH.ClassName "footer footer-vertical sm:footer-horizontal bg-base-200 text-base-content p-6 sm:p-10 mt-12" ] ]
    [ HH.aside_
        [ HH.img [ HP.src "./images/E7D/PNG Logo Files/Transparent Logo.png", HP.alt "ENTANGLED Labs", HP.classes [ HH.ClassName "w-12 sm:w-16" ] ]
        , HH.p [ HP.classes [ HH.ClassName "text-sm sm:text-base" ] ]
            [ HH.text "ENTANGLED Labs"
            , HH.br_
            , HH.text "Secure staking • Expert development • Trusted partner"
            ]
        ]
    , HH.nav_
        [ HH.h6 [ HP.classes [ HH.ClassName "footer-title text-sm sm:text-base" ] ] [ HH.text "Company" ]
        , HH.a [ HP.classes [ HH.ClassName "link link-hover text-sm sm:text-base" ], HP.href "#about" ] [ HH.text "About" ]
        , HH.a [ HP.classes [ HH.ClassName "link link-hover text-sm sm:text-base" ], HP.href "#services" ] [ HH.text "Services" ]
        , HH.a [ HP.classes [ HH.ClassName "link link-hover text-sm sm:text-base" ], HP.href "#pool" ] [ HH.text "Pool" ]
        ]
    , HH.nav_
        [ HH.h6 [ HP.classes [ HH.ClassName "footer-title text-sm sm:text-base" ] ] [ HH.text "Links" ]
        , HH.a [ HP.classes [ HH.ClassName "link link-hover text-sm sm:text-base" ], HP.target "_blank", HP.href "https://github.com/en7angled/" ] [ HH.text "GitHub" ]
        ]
    ]

-- ==============================================================================
-- FAB Speed Dial (App-specific Floating Action Button)
-- ==============================================================================
renderFabFlower :: forall w i. HH.HTML w i
renderFabFlower =
  HH.div [ HP.classes [ HH.ClassName "fab" ] ]
    [ HH.div
        [ HP.tabIndex 0
        , HP.attr (HH.AttrName "role") "button"
        , HP.classes [ HH.ClassName "btn btn-lg btn-circle btn-accent" ]
        ]
        [ starIcon ]
    , HH.div [ HP.classes [ HH.ClassName "fab-close" ] ]
        [ HH.text "Close "
        , HH.span [ HP.classes [ HH.ClassName "btn btn-circle btn-lg btn-error" ] ]
            [ HH.text "✕" ]
        ]
    , HH.div_
        [ HH.span [ HP.classes [ HH.ClassName "bg-base-100 text-accent" ] ] [ HH.text "BJJ Belts" ]
        , HH.a
            [ HP.classes [ HH.ClassName "btn btn-lg btn-circle bg-accent text-accent-content" ]
            , HP.href "https://bjj.cardano.vip"
            , HP.target "_blank"
            ]
            [ medalIcon ]
        ]
    , HH.div_
        [ HH.span [ HP.classes [ HH.ClassName "bg-base-100 text-accent" ] ] [ HH.text "Raffleize Art" ]
        , HH.a
            [ HP.classes [ HH.ClassName "btn btn-lg btn-circle bg-accent text-accent-content" ]
            , HP.href "https://github.com/mariusgeorgescu/raffleize"
            , HP.target "_blank"
            ]
            [ paletteIcon ]
        ]
    , HH.div_
        [ HH.span [ HP.classes [ HH.ClassName "bg-base-100 text-accent" ] ] [ HH.text "Cardano Ticker" ]
        , HH.a
            [ HP.classes [ HH.ClassName "btn btn-lg btn-circle bg-accent text-accent-content" ]
            , HP.href "https://github.com/en7angled/CardanoTicker/tree/main"
            , HP.target "_blank"
            ]
            [ chartIcon ]
        ]
    ]
  where
  starIcon :: forall w' i'. HH.HTML w' i'
  starIcon =
    SE.svg
      [ SA.class_ $ HH.ClassName "h-6 w-6 shrink-0 stroke-current"
      , SA.fill NoColor
      , SA.viewBox 0.0 0.0 24.0 24.0
      ]
      [ SE.path
          [ SA.strokeLineCap LineCapRound
          , SA.strokeLineJoin LineJoinRound
          , SA.strokeWidth 2.0
          , HP.attr (HH.AttrName "d") "M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"
          ]
      ]

  paletteIcon :: forall w' i'. HH.HTML w' i'
  paletteIcon =
    SE.svg
      [ SA.class_ $ HH.ClassName "h-6 w-6 shrink-0 stroke-current"
      , SA.fill NoColor
      , SA.viewBox 0.0 0.0 24.0 24.0
      ]
      [ SE.path
          [ SA.strokeLineCap LineCapRound
          , SA.strokeLineJoin LineJoinRound
          , SA.strokeWidth 2.0
          , HP.attr (HH.AttrName "d") "M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"
          ]
      ]

  medalIcon :: forall w' i'. HH.HTML w' i'
  medalIcon =
    SE.svg
      [ SA.class_ $ HH.ClassName "h-6 w-6 shrink-0 stroke-current"
      , SA.fill NoColor
      , SA.viewBox 0.0 0.0 24.0 24.0
      ]
      [ SE.path
          [ SA.strokeLineCap LineCapRound
          , SA.strokeLineJoin LineJoinRound
          , SA.strokeWidth 2.0
          , HP.attr (HH.AttrName "d") "M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"
          ]
      ]

  chartIcon :: forall w' i'. HH.HTML w' i'
  chartIcon =
    SE.svg
      [ SA.class_ $ HH.ClassName "h-6 w-6 shrink-0 stroke-current"
      , SA.fill NoColor
      , SA.viewBox 0.0 0.0 24.0 24.0
      ]
      [ SE.path
          [ SA.strokeLineCap LineCapRound
          , SA.strokeLineJoin LineJoinRound
          , SA.strokeWidth 2.0
          , HP.attr (HH.AttrName "d") "M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z"
          ]
      ]
