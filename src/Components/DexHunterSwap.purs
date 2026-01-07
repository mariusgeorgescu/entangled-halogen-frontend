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
containerId = "dexhunter-swap-container"

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
    [ HH.div
        [ HP.classes [ HH.ClassName "container mx-auto px-4 py-8" ] ]
        [ -- Header section
          HH.div
            [ HP.classes [ HH.ClassName "text-center mb-8" ] ]
            [ HH.h1
                [ HP.classes [ HH.ClassName "text-3xl md:text-4xl font-bold mb-4" ] ]
                [ HH.text "Token Swap" ]
            , HH.p
                [ HP.classes [ HH.ClassName "text-base-content/70 max-w-2xl mx-auto" ] ]
                [ HH.text "Swap tokens securely using DexHunter's aggregated liquidity across Cardano DEXs." ]
            ]
        , -- Wallet connection status
          renderWalletStatus state.walletApi
        , -- DexHunter widget container (full width for chart + orders layout)
          HH.div
            [ HP.id containerId
            , HP.classes [ HH.ClassName "w-full" ]
            ]
            [ -- Loading placeholder until React mounts
              if state.mounted then HH.text ""
              else renderLoadingPlaceholder
            ]
        , -- Back to home button
          renderBackButton GoHome
        ]
    ]

renderWalletStatus :: forall w i. Maybe Api -> HH.HTML w i
renderWalletStatus = case _ of
  Just _ ->
    HH.div
      [ HP.classes [ HH.ClassName "alert alert-success alert-soft max-w-2xl mx-auto mb-6" ] ]
      [ HH.span [ HP.classes [ HH.ClassName "text-sm" ] ]
          [ HH.text "✓ Wallet connected - You can swap tokens directly" ]
      ]
  Nothing ->
    HH.div
      [ HP.classes [ HH.ClassName "alert alert-info alert-soft max-w-2xl mx-auto mb-6" ] ]
      [ HH.span [ HP.classes [ HH.ClassName "text-sm" ] ]
          [ HH.text "Connect your wallet in the navbar to enable swaps" ]
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

