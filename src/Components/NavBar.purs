module Components.NavBar where

import Prelude
import AppEnv (Env)
import Cardano.Capabilities.Wallet.MonadCIP30 (class MonadCIP30, getNetworkId)
import Cardano.Wallet.Cip30 (Api)
import Control.Monad.Reader.Class (class MonadAsk, ask)
import Data.Array (elem)
import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Store.Connect (Connected, connect)
import Halogen.Store.Monad (class MonadStore, updateStore)
import Halogen.Store.Select (selectAll)
import Store as Store
import Effect.Console (log) as Console
import Type.Proxy (Proxy(..))
import Components.WalletConnectComponent as WC

--------------------------------------------------------------------------------
-- * Component Interface
--------------------------------------------------------------------------------
type Slot
  = H.Slot Query Output Unit

navbarProxy = Proxy :: Proxy "navbarWidget"

type Input
  = Unit

type StoreContext
  = Store.Store

data Query a
  = GetWalletApi (Maybe Api -> a)

data Output
  = WalletConnectEvent
  | InvalidNetworkEvent Int
  | HomeEvent
  | AboutEvent
  | SwapEvent
  | BuildTransactionEvent String Api

--------------------------------------------------------------------------------
-- * Child Slots
--------------------------------------------------------------------------------
type Slots
  = ( walletConnectComponent :: H.Slot WC.Query WC.Output Unit
    )

--------------------------------------------------------------------------------
-- * Component Definition
--------------------------------------------------------------------------------
type State
  = { walletApi :: Maybe Api
    }

data Action
  = Initialize
  | Receive (Connected StoreContext Input)
  | HandleWalletConnectOutput WC.Output
  | HomeButton
  | AboutButton
  | SwapButton

component ::
  forall m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadAsk Env m =>
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
                , receive = Just <<< Receive
                }
        }

--------------------------------------------------------------------------------
-- * Component Evalution Logic
--------------------------------------------------------------------------------
initialState :: Connected StoreContext Input -> State
initialState x =
  { walletApi: x.context.walletApi
  }

handleQuery ::
  forall m a.
  MonadAff m =>
  Query a -> H.HalogenM State Action Slots Output m (Maybe a)
handleQuery = case _ of
  GetWalletApi k -> do
    walletApi <- H.gets _.walletApi
    pure $ Just (k walletApi)

handleAction ::
  forall m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadAsk Env m =>
  MonadStore Store.Action Store.Store m =>
  Action → H.HalogenM State Action Slots Output m Unit
handleAction = case _ of
  Initialize -> do
    walletApi <- H.gets _.walletApi
    void $ H.query WC.walletConnectProxy unit (WC.SetWalletApi walletApi unit)
  Receive x -> do
    H.modify_ _ { walletApi = x.context.walletApi }
    handleAction Initialize
  HandleWalletConnectOutput out -> case out of
    WC.WalletConnectedEvent -> do
      mApi <- H.query WC.walletConnectProxy unit (WC.GetWalletApi identity)
      mWalletInfo <- H.query WC.walletConnectProxy unit (WC.GetConnectedWalletInfo identity)
      case mApi, mWalletInfo of
        Just (Just api), Just (Just walletInfo) -> do
          updateStore (Store.Connect api (walletInfo.connectedWalletName))
          H.raise WalletConnectEvent
          env <- ask
          currentNetworkId <- getNetworkId api
          if (currentNetworkId /= env.allowedNetworkId) then do
            H.liftEffect $ Console.log $ show $ "Invalid network: " <> show currentNetworkId <> " <> " <> show env.allowedNetworkId
            void $ H.query WC.walletConnectProxy unit (WC.DisconnectWalletQuery unit)
            handleAction (HandleWalletConnectOutput WC.WalletDisconnectedEvent)
            H.raise $ InvalidNetworkEvent currentNetworkId
          else
            pure unit
        _, _ -> pure unit
    WC.WalletDisconnectedEvent -> do
      updateStore Store.Disconnect
      H.raise WalletConnectEvent
    WC.CustomButtonEvent bid -> do
      H.liftEffect $ Console.log $ show bid
      case bid of
        "home" -> H.raise HomeEvent
        "about" -> H.raise AboutEvent
        userAction
          | userAction `elem` [ "DelegateToPool", "DelegateToDRep", "DelegateToPoolAndDRep" ] -> do
            walletApi <- H.gets _.walletApi
            case walletApi of
              Just api -> do
                H.liftEffect $ Console.log $ show $ "DelegateEvent: " <> userAction
                H.raise $ BuildTransactionEvent userAction api
              Nothing -> pure unit
        _ -> H.liftEffect $ Console.log $ show "Unknown button event"
  HomeButton -> H.raise HomeEvent
  AboutButton -> H.raise AboutEvent
  SwapButton -> H.raise SwapEvent

--------------------------------------------------------------------------------
-- * Component Rendering
--------------------------------------------------------------------------------
render :: forall m. MonadAff m => MonadCIP30 m => State -> H.ComponentHTML Action Slots m
render _state =
  HH.div
    [ HP.classes [ HH.ClassName "bg-base-100 text-base-content sticky top-0 z-30 flex h-16 w-full justify-center bg-opacity-90 backdrop-blur transition-shadow duration-100 [transform:translate3d(0,0,0)] shadow-sm" ]
    ]
    [ HH.div
        [ HP.classes [ HH.ClassName "navbar bg-neutral text-neutral-content gap-2 sm:gap-4 px-2 sm:px-4" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "flex-1 min-w-0" ] ]
            [ HH.button
                ([ HP.classes [ HH.ClassName ("btn btn-sm sm:btn-md md:btn-lg btn-ghost p-1 sm:p-2") ], HE.onClick (\_ -> HomeButton) ])
                [ HH.img
                    [ HP.src "./images/E7D/SVG Vector Files/Transparent Logo.svg"
                    , HP.alt "E7D Logo"
                    , HP.classes [ HH.ClassName "h-12 sm:h-16 md:h-20 w-auto" ]
                    ]
                ]
            ]
        , HH.div [ HP.classes [ HH.ClassName "flex-2 flex justify-end items-center min-w-0" ] ]
            [ HH.div [ HP.classes [ HH.ClassName "hidden sm:flex items-center gap-2 mr-2" ] ]
                [ HH.button
                    [ HP.classes [ HH.ClassName "btn btn-ghost btn-sm gap-1.5 font-medium hover:bg-base-100/20 transition-all duration-200" ]
                    , HE.onClick (\_ -> SwapButton)
                    ]
                    [ HH.span [ HP.classes [ HH.ClassName "text-lg" ] ] [ HH.text "🔄" ]
                    , HH.span [ HP.classes [ HH.ClassName "hidden md:inline" ] ] [ HH.text "Swap" ]
                    ]
                , HH.button
                    [ HP.classes [ HH.ClassName "btn btn-ghost btn-sm gap-1.5 font-medium hover:bg-base-100/20 transition-all duration-200" ]
                    , HE.onClick (\_ -> AboutButton)
                    ]
                    [ HH.img
                        [ HP.src "./images/about-symbol.svg"
                        , HP.alt "About"
                        , HP.classes [ HH.ClassName "w-5 h-5 opacity-80" ]
                        ]
                    , HH.span [ HP.classes [ HH.ClassName "hidden md:inline" ] ] [ HH.text "About Us" ]
                    ]
                ]
            , HH.slot WC.walletConnectProxy unit WC.component { buttons: customButtons, assets: { connectIcon: "./images/walletsymbol.svg", disconnectIcon: "./images/disconnectsymbol.svg" } } HandleWalletConnectOutput
            ]
        , HH.div [ HP.classes [ HH.ClassName "flex-none" ] ] []
        ]
    ]
  where
  customButtons =
    [ { id: "home", label: "Home", iconSrc: "./images/home-symbol.svg", classes: [ "btn-secondary" ] }
    , { id: "DelegateToPool", label: "Stake with us", iconSrc: "./images/support-icon.svg", classes: [ "btn-primary" ] }
    , { id: "DelegateToDRep", label: "Let us be your DRep", iconSrc: "./images/vote_icon.svg", classes: [ "btn-primary" ] }
    , { id: "DelegateToPoolAndDRep", label: "Both of the above", iconSrc: "./images/verified-check.svg", classes: [ "btn-primary" ] }
    ]
