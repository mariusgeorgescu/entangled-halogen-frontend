module Components.NavBar where

import Prelude
import AppEnv (Env)
import Capabilities.MonadCIP30 (class MonadCIP30)
import Capabilities.MonadInteraction (class MonadInteraction)
import Cardano.Wallet.Cip30 (Api)
import Control.Monad.Reader.Class (class MonadAsk)
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
import Test.Unit.Console (consoleLog)
import Type.Proxy (Proxy(..))
import WalletConnect.Component as WC
import Data.Array (elem)

--------------------------------------------------------------------------------
-- * Component Interface
--------------------------------------------------------------------------------
type Slot
  = forall query. H.Slot query Output Unit

navbarProxy = Proxy :: Proxy "navbarWidget"

type Input
  = Unit

type StoreContext
  = Store.Store

data Output
  = WalletConnectEvent
  | InvalidNetworkEvent
  | HomeEvent
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

component ::
  forall query m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadAsk Env m =>
  MonadStore Store.Action Store.Store m =>
  H.Component query Input Output m
component =
  connect (selectAll)
    $ H.mkComponent
        { initialState
        , render
        , eval:
            H.mkEval
              H.defaultEval
                { handleAction = handleAction
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

handleAction ::
  forall m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadAsk Env m =>
  MonadInteraction String m =>
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
      case mApi of
        Just (Just api) -> do
          updateStore (Store.Connect api)
          H.raise WalletConnectEvent
        _ -> pure unit
    WC.WalletDisconnectedEvent -> do
      updateStore Store.Disconnect
      H.raise WalletConnectEvent
    WC.CustomButtonEvent bid -> do
      H.liftEffect $ consoleLog $ show bid
      case bid of
        "home" -> H.raise HomeEvent
        userAction | userAction `elem` ["DelegateToPool", "DelegateToDRep", "DelegateToPoolAndDRep"] -> do
          walletApi <- H.gets _.walletApi
          case walletApi of
            Just api -> do
              H.liftEffect $ consoleLog $ show $ "DelegateEvent: " <> userAction
              H.raise $ BuildTransactionEvent userAction api
            Nothing -> pure unit
        _ -> H.liftEffect $ consoleLog $ show "Unknown button event"
  HomeButton -> H.raise HomeEvent

--------------------------------------------------------------------------------
-- * Component Rendering
--------------------------------------------------------------------------------
render :: forall m. MonadAff m => MonadCIP30 m => State -> H.ComponentHTML Action Slots m
render state =
  HH.div
    [ HP.classes [ HH.ClassName "bg-base-100 text-base-content sticky top-0 z-30 flex h-16 w-full justify-center bg-opacity-90 backdrop-blur transition-shadow duration-100 [transform:translate3d(0,0,0)] shadow-sm" ]
    ]
    [ HH.div
        [ HP.classes [ HH.ClassName "navbar bg-neutral text-neutral-content gap-4" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "flex-1" ] ]
            [ HH.button
                ([ HP.classes [ HH.ClassName ("btn btn-ghost") ], HE.onClick (\_ -> HomeButton) ])
                [ HH.img
                    [ HP.src "./images/E7D/SVG Vector Files/Transparent Logo.svg"
                    , HP.alt "E7D Logo"
                    , HP.classes [ HH.ClassName "h-12" ]
                    ]
                ]
            ]
        , HH.div [ HP.classes [ HH.ClassName "flex-2 flex justify-end" ] ]
            [ HH.slot WC.walletConnectProxy unit WC.component { buttons: customButtons, assets: { connectIcon: "./images/walletsymbol.svg", disconnectIcon: "./images/disconnectsymbol.svg" } } HandleWalletConnectOutput
            ]
        , HH.div [ HP.classes [ HH.ClassName "flex-none" ] ] []
        ]
    ]
  where
  customButtons =
    [ { id: "home", label: "Home", iconSrc: "./images/home-symbol.svg", classes: [ "btn-secondary" ] }
    , { id: "DelegateToPool", label: "Delegate to [E7D] Pool", iconSrc: "./images/support-icon.svg", classes: [ "btn-primary" ] }
    , { id: "DelegateToDRep", label: "Delegate to [MG] DRep", iconSrc: "./images/vote_icon.svg", classes: [ "btn-primary" ] }
    , { id: "DelegateToPoolAndDRep", label: "Delegate to [E7D] Pool and [MG] DRep", iconSrc: "./images/certificate-love.svg", classes: [ "btn-primary" ] }
    ]
