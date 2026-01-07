module Components.DexHunterSwap
  ( component
  , swapProxy
  , Query(..)
  , Output(..)
  , Slot
  , SwapConfig
  , defaultSwapConfig
  ) where

import Prelude

import Cardano.Wallet.Cip30 (Api)
import Components.HTML.RenderUtils.App (renderBackButton)
import Data.Maybe (Maybe(..), isJust, fromMaybe)
import Effect (Effect)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.Store.Connect (Connected, connect)
import Halogen.Store.Monad (class MonadStore)
import Halogen.Store.Select (selectAll)
import Store as Store
import Type.Proxy (Proxy(..))

--------------------------------------------------------------------------------
-- * FFI Imports
--------------------------------------------------------------------------------
-- isMobile flag controls whether chart and orders are shown (only on mobile)
foreign import mountDexHunterSwapImpl :: String -> SwapConfigJS -> Boolean -> Effect Unit
foreign import mountDexHunterWithWalletImpl :: String -> SwapConfigJS -> Api -> String -> Boolean -> Effect Unit
foreign import unmountDexHunterSwapImpl :: String -> Effect Unit
foreign import getIsMobileImpl :: Effect Boolean

--------------------------------------------------------------------------------
-- * Types
--------------------------------------------------------------------------------
type SwapConfig =
  { partnerName :: String
  , partnerCode :: String
  , defaultTokenIn :: String
  , defaultTokenOut :: String
  , orderTypes :: Array String
  , theme :: String
  }

type SwapConfigJS =
  { partnerName :: String
  , partnerCode :: String
  , defaultTokenIn :: String
  , defaultTokenOut :: String
  , orderTypes :: Array String
  , theme :: String
  }

defaultSwapConfig :: SwapConfig
defaultSwapConfig =
  { partnerName: "E7D"
  , partnerCode: "" -- You can get a partner code from DexHunter
  , defaultTokenIn: "" -- ADA
  , defaultTokenOut: "" -- Empty for default
  , orderTypes: [ "SWAP", "LIMIT" ]
  , theme: "dark"
  }

--------------------------------------------------------------------------------
-- * Component Interface
--------------------------------------------------------------------------------
type Slot = H.Slot Query Output Unit

swapProxy :: Proxy "swapWidget"
swapProxy = Proxy

type Input =
  { config :: SwapConfig
  }

type StoreContext = Store.Store

data Query a
  = RefreshWidget a

data Output
  = TransactionSubmitted String
  | SwapError String
  | GoToHome

--------------------------------------------------------------------------------
-- * Component Definition
--------------------------------------------------------------------------------
type State =
  { config :: SwapConfig
  , walletApi :: Maybe Api
  , walletName :: Maybe String
  , mounted :: Boolean
  }

data Action
  = Initialize
  | Finalize
  | Receive (Connected StoreContext Input)
  | MountWidget
  | WalletChanged (Maybe Api)
  | GoHome

containerId :: String
containerId = "dexhunter-container"

component ::
  forall m.
  MonadAff m =>
  MonadStore Store.Action Store.Store m =>
  H.Component Query Input Output m
component =
  connect (selectAll)
    $ H.mkComponent
        { initialState
        , render
        , eval:
            H.mkEval
              H.defaultEval
                { handleAction = handleAction
                , handleQuery = handleQuery
                , initialize = Just Initialize
                , finalize = Just Finalize
                , receive = Just <<< Receive
                }
        }

--------------------------------------------------------------------------------
-- * Component Evaluation Logic
--------------------------------------------------------------------------------
initialState :: Connected StoreContext Input -> State
initialState { context, input } =
  { config: input.config
  , walletApi: context.walletApi
  , walletName: context.walletName
  , mounted: false
  }

handleQuery ::
  forall m a.
  MonadAff m =>
  MonadStore Store.Action Store.Store m =>
  Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  RefreshWidget a -> do
    handleAction MountWidget
    pure $ Just a

handleAction ::
  forall m.
  MonadAff m =>
  MonadStore Store.Action Store.Store m =>
  Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    -- Delay mounting to ensure DOM is ready
    H.liftAff $ H.liftAff $ pure unit
    handleAction MountWidget
  Finalize -> do
    liftEffect $ unmountDexHunterSwapImpl containerId
  Receive { context, input } -> do
    currentApi <- H.gets _.walletApi
    let newApi = context.walletApi
    let newName = context.walletName
    -- Check if wallet state changed (connected/disconnected)
    let walletChanged = isJust currentApi /= isJust newApi
    liftEffect $ log $ "DexHunter: Receive - currentApi: " <> show (isJust currentApi) <> ", newApi: " <> show (isJust newApi) <> ", walletName: " <> show newName <> ", changed: " <> show walletChanged
    H.modify_ _ 
      { config = input.config
      , walletApi = newApi
      , walletName = newName
      }
    -- Re-mount widget if wallet connection state changed
    when walletChanged $ do
      liftEffect $ log "DexHunter: Wallet state changed, remounting widget"
      handleAction MountWidget
  MountWidget -> do
    state <- H.get
    let configJS = toConfigJS state.config
    let walletNameStr = fromMaybe "" state.walletName
    -- Detect if on mobile screen to show/hide chart and orders
    isMobile <- liftEffect getIsMobileImpl
    liftEffect $ log $ "DexHunter: isMobile = " <> show isMobile
    case state.walletApi of
      Just api -> do
        liftEffect $ mountDexHunterWithWalletImpl containerId configJS api walletNameStr isMobile
        H.modify_ _ { mounted = true }
      Nothing -> do
        -- Mount widget without wallet integration
        -- User can connect wallet through the navbar
        liftEffect $ mountDexHunterSwapImpl containerId configJS isMobile
        H.modify_ _ { mounted = true }
  WalletChanged mApi -> do
    H.modify_ _ { walletApi = mApi }
    handleAction MountWidget
  GoHome -> H.raise GoToHome

toConfigJS :: SwapConfig -> SwapConfigJS
toConfigJS config =
  { partnerName: config.partnerName
  , partnerCode: config.partnerCode
  , defaultTokenIn: config.defaultTokenIn
  , defaultTokenOut: config.defaultTokenOut
  , orderTypes: config.orderTypes
  , theme: config.theme
  }

--------------------------------------------------------------------------------
-- * Component Rendering
--------------------------------------------------------------------------------
render :: forall m. MonadAff m => State -> H.ComponentHTML Action () m
render state =
  HH.div
    [ HP.classes [ HH.ClassName "min-h-screen bg-base-200" ] ]
    [ -- Hero Header Section
      renderHeroHeader
    , HH.div
        [ HP.classes [ HH.ClassName "container mx-auto px-4 py-8" ] ]
        [  -- Wallet connection status
          renderWalletStatus state.walletApi
        , -- DexHunter widget container (full width for chart + orders layout)
          -- relative position and min-height to allow modal dropdowns to overlay properly
          HH.div
            [ HP.id containerId
            , HP.classes [ HH.ClassName "w-full relative" ]
            , HP.style "min-height: 600px;"
            ]
            [ -- Loading placeholder until React mounts
              if state.mounted then HH.text ""
              else renderLoadingPlaceholder
            ]
        , -- How it works section
          renderHowItWorks
        , -- Back to home button
          renderBackButton GoHome
        ]
    ]

-- | Hero header with gradient text and encouraging message
renderHeroHeader :: forall w i. HH.HTML w i
renderHeroHeader =
  HH.div
    [ HP.classes [ HH.ClassName "hero bg-gradient-to-br from-base-300 via-base-200 to-base-300 pt-8 pb-12" ] ]
    [ HH.div
        [ HP.classes [ HH.ClassName "hero-content text-center" ] ]
        [ HH.div
            [ HP.classes [ HH.ClassName "max-w-3xl" ] ]
            [ -- Main Title with gradient
              HH.h1
                [ HP.classes [ HH.ClassName "text-4xl md:text-5xl lg:text-6xl font-black mb-6" ] ]
                [ HH.span
                    [ HP.classes [ HH.ClassName "bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-transparent" ] ]
                    [ HH.text "Swap Tokens" ]
                , HH.br_
                , HH.span
                    [ HP.classes [ HH.ClassName "text-base-content" ] ]
                    [ HH.text "Like a Pro" ]
                ]
            , -- Subtitle
              HH.p
                [ HP.classes [ HH.ClassName "text-lg md:text-xl text-base-content/70 mb-6 max-w-2xl mx-auto" ] ]
                [ HH.text "Get the "
                , HH.span [ HP.classes [ HH.ClassName "text-primary font-semibold" ] ] [ HH.text "best rates" ]
                , HH.text " across all Cardano DEXs. Our smart routing finds optimal paths for your swaps."
                ]
            , -- Quick benefits
              HH.div
                [ HP.classes [ HH.ClassName "flex flex-wrap justify-center gap-3" ] ]
                [ renderBenefitBadge "🔒" "Secure"
                , renderBenefitBadge "⚡" "Fast"
                , renderBenefitBadge "💰" "Best Rates"
                , renderBenefitBadge "🔄" "Multi-DEX"
                ]
            ]
        ]
    ]

-- | Small benefit badge
renderBenefitBadge :: forall w i. String -> String -> HH.HTML w i
renderBenefitBadge icon label =
  HH.span
    [ HP.classes [ HH.ClassName "badge badge-outline badge-lg gap-1 py-3" ] ]
    [ HH.text $ icon <> " " <> label ]


-- | How it works section
renderHowItWorks :: forall w i. HH.HTML w i
renderHowItWorks =
  HH.div
    [ HP.classes [ HH.ClassName "mt-12 mb-8" ] ]
    [ HH.div
        [ HP.classes [ HH.ClassName "divider text-lg font-semibold" ] ]
        [ HH.text "✨ How It Works" ]
    , HH.ul
        [ HP.classes [ HH.ClassName "steps steps-vertical lg:steps-horizontal w-full mt-6" ] ]
        [ HH.li
            [ HP.classes [ HH.ClassName "step" ] ]
            [ HH.div
                [ HP.classes [ HH.ClassName "text-left lg:text-center" ] ]
                [ HH.span [ HP.classes [ HH.ClassName "font-bold" ] ] [ HH.text "Connect Wallet" ]
                , HH.br_
                , HH.span [ HP.classes [ HH.ClassName "text-sm text-base-content/60" ] ] [ HH.text "Use the navbar button" ]
                ]
            ]
        , HH.li
            [ HP.classes [ HH.ClassName "step" ] ]
            [ HH.div
                [ HP.classes [ HH.ClassName "text-left lg:text-center" ] ]
                [ HH.span [ HP.classes [ HH.ClassName "font-bold" ] ] [ HH.text "Select Tokens" ]
                , HH.br_
                , HH.span [ HP.classes [ HH.ClassName "text-sm text-base-content/60" ] ] [ HH.text "Choose what to swap" ]
                ]
            ]
        , HH.li
            [ HP.classes [ HH.ClassName "step" ] ]
            [ HH.div
                [ HP.classes [ HH.ClassName "text-left lg:text-center" ] ]
                [ HH.span [ HP.classes [ HH.ClassName "font-bold" ] ] [ HH.text "Enter Amount" ]
                , HH.br_
                , HH.span [ HP.classes [ HH.ClassName "text-sm text-base-content/60" ] ] [ HH.text "See real-time rates" ]
                ]
            ]
        , HH.li
            [ HP.classes [ HH.ClassName "step" ] ]
            [ HH.div
                [ HP.classes [ HH.ClassName "text-left lg:text-center" ] ]
                [ HH.span [ HP.classes [ HH.ClassName "font-bold" ] ] [ HH.text "Swap!" ]
                , HH.br_
                , HH.span [ HP.classes [ HH.ClassName "text-sm text-base-content/60" ] ] [ HH.text "Sign & confirm" ]
                ]
            ]
        ]
    , -- Encouraging CTA
      HH.div
        [ HP.classes [ HH.ClassName "text-center mt-8 p-6 bg-gradient-to-r from-primary/10 via-secondary/10 to-accent/10 rounded-box" ] ]
        [ HH.p
            [ HP.classes [ HH.ClassName "text-lg font-medium mb-2" ] ]
            [ HH.text "🚀 Ready to trade? " ]
        , HH.p
            [ HP.classes [ HH.ClassName "text-base-content/70" ] ]
            [ HH.text "Connect your wallet above and start swapping tokens with the best rates on Cardano!" ]
        ]
    ]

renderWalletStatus :: forall w i. Maybe Api -> HH.HTML w i
renderWalletStatus = case _ of
  Just _ ->
    HH.div
      [ HP.classes [ HH.ClassName "alert alert-success alert-soft max-w-2xl mx-auto mb-6" ] ]
      [ HH.span [ HP.classes [ HH.ClassName "text-sm" ] ]
          [ HH.text "✓ Wallet connected - You can swap tokens with the best rates on Cardano!" ]
      ]
  Nothing ->
    HH.div
      [ HP.classes [ HH.ClassName "alert alert-info alert-soft max-w-2xl mx-auto mb-6" ] ]
      [ HH.span [ HP.classes [ HH.ClassName "text-sm" ] ]
          [ HH.text "Connect your wallet in the navbar to enable swaps!" ]
      ]

renderLoadingPlaceholder :: forall w i. HH.HTML w i
renderLoadingPlaceholder =
  HH.div
    [ HP.classes [ HH.ClassName "flex flex-col items-center justify-center h-80 gap-4" ] ]
    [ HH.span
        [ HP.classes [ HH.ClassName "loading loading-spinner loading-lg text-primary" ] ]
        []
    , HH.p
        [ HP.classes [ HH.ClassName "text-base-content/60" ] ]
        [ HH.text "Loading swap interface..." ]
    ]

