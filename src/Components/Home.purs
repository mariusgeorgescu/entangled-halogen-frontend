module Components.Home where

import Capabilities.MonadInteraction (class MonadInteraction, buildTransaction, defaultServerEnv, signTransaction, submitTransaction)
import Data.Time.Duration (Milliseconds(..))
import Prelude
import AppEnv (Env)
import Capabilities.MonadCIP30 (class MonadCIP30)
import Cardano.Wallet.Cip30 as Cardano.Wallet.Cip30
import Components.HTML.RenderUtils.App (renderCexplorerPoolGraphSection, renderFabFlower, renderFooterSection, renderHeroSection, renderPoolOverviewSection, renderProfessionalServicesSection, renderToasts) as RU
import Components.NavBar as NavBar
import Control.Monad.Reader.Class (class MonadAsk, asks)
import Control.Monad.Rec.Class (forever)
import Data.Array (cons, filter)
import Data.DateTime.Instant (unInstant)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Tuple (Tuple(..))
import Effect.Aff as Aff
import Effect.Aff.Class (class MonadAff)
import Effect.Now (now)
import Halogen as H
import Halogen.HTML as HH
import Halogen.Store.Monad (class MonadStore)
import Halogen.Subscription as HS
import Store as Store
import Test.Unit.Console (consoleLog)

--------------------------------------------------------------------------------
-- * Utils
--------------------------------------------------------------------------------
type Toast
  = { remainingSeconds :: Int
    , alertType :: String
    , message :: String
    }

getToast :: Toast -> Tuple String String
getToast t = Tuple t.alertType t.message

decrementToats :: Array Toast -> Array Toast
decrementToats ts = (\t -> t { remainingSeconds = t.remainingSeconds - 1 }) <$> ts

clearToasts :: Array Toast -> Array Toast
clearToasts ts = filter ((_ > 0) <<< _.remainingSeconds) ts

--------------------------------------------------------------------------------
-- * Component Definition
--------------------------------------------------------------------------------
type Slots
  = ( navbarWidget :: NavBar.Slot
    )

data Page
  = MainPage

derive instance eqValue :: Eq Page

type Input
  = {
    }

type State
  = { toasts :: Array Toast
    , currentPage :: Page
    , currentTime :: Number
    }

data Action
  = Initialize
  | HandleNavBarOutput NavBar.Output
  | SubmitTransaction String String
  | SignTransaction Cardano.Wallet.Cip30.Api String
  | Tick

component ::
  forall query output m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadStore Store.Action Store.Store m =>
  MonadAsk Env m =>
  MonadInteraction String m =>
  H.Component query Input output m
component =
  H.mkComponent
    { initialState
    , render
    , eval:
        H.mkEval
          $ H.defaultEval
              { handleAction = handleAction
              , initialize = Just Initialize
              }
    }

--------------------------------------------------------------------------------
-- * Component Evaluation Logic
--------------------------------------------------------------------------------
initialState :: Input -> State
initialState i = { currentPage: MainPage, toasts: [], currentTime: 0.0 }

handleAction ::
  forall output m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadStore Store.Action Store.Store m =>
  MonadAsk Env m =>
  MonadInteraction String m =>
  Action -> H.HalogenM State Action Slots output m Unit
handleAction action = case action of
  Initialize -> do
    -- Subscribe to get the current time at a regular interval
    void $ H.subscribe =<< createTimerEmitter Tick
    pure unit
    where
    createTimerEmitter :: forall a n. MonadAff n => a -> n (HS.Emitter a)
    createTimerEmitter val = do
      { emitter, listener } <- H.liftEffect HS.create
      _ <-
        H.liftAff $ Aff.forkAff
          $ forever do
              Aff.delay $ Milliseconds 1000.0
              H.liftEffect $ HS.notify listener val
      pure emitter
  Tick -> do
    ct <- unwrap <<< unInstant <$> H.liftEffect now
    ts <- H.gets _.toasts
    let
      newTs = clearToasts <<< decrementToats $ ts
    H.modify_ _ { currentTime = ct, toasts = newTs }
  SignTransaction api unsignedTxCbor -> do
    signedTxResult <- signTransaction @String api unsignedTxCbor
    case signedTxResult of
      Right signedTxCbor -> do
        H.modify_ \s -> s { toasts = txSubmitSuccessToast  `cons` s.toasts }
        handleAction (SubmitTransaction unsignedTxCbor signedTxCbor)
      Left err -> do
        H.modify_ \s -> s { toasts = txSubmitFailedToast err `cons` s.toasts }
    pure unit
  SubmitTransaction unsignedTxCbor signedTx -> do
    submitResult <- submitTransaction @String defaultServerEnv unsignedTxCbor signedTx
    case submitResult of
      Right txId -> do
        H.modify_ \s -> s { toasts = txConfirmedSuccessToast txId `cons` s.toasts }
      Left err -> do
        H.modify_ \s -> s { toasts = txConfirmedFailedToast err `cons` s.toasts }
    H.liftEffect $ consoleLog $ show submitResult
    pure unit
  HandleNavBarOutput navbarout -> case navbarout of
    NavBar.HomeEvent -> do
      pure unit
    NavBar.BuildTransactionEvent userAction api -> do
      buildResult <- buildTransaction defaultServerEnv api userAction
      H.liftEffect $ consoleLog $ show buildResult
      case buildResult of
        Right txCbor -> do
          H.modify_ \s -> s { toasts = txBuildSuccessToast `cons` s.toasts }
          handleAction (SignTransaction api txCbor)
        Left err -> do
          H.modify_ \s -> s { toasts = txBuildFailedToast err `cons` s.toasts }
      pure unit
    NavBar.WalletConnectEvent -> pure unit
    NavBar.InvalidNetworkEvent -> do
      cardanoNetwork <- asks _.blockchainProviderConfig.cardanoNetwork
      let
        newToast = { remainingSeconds: 5, alertType: "error", message: "Your wallet has to be connected to Cardano " <> cardanoNetwork <> " network" }
      H.modify_ \s -> s { toasts = newToast `cons` s.toasts }

--------------------------------------------------------------------------------
-- * Component Rendering
--------------------------------------------------------------------------------
render ::
  forall m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadStore Store.Action Store.Store m =>
  MonadAsk Env m =>
  State -> H.ComponentHTML Action Slots m
render s =
  HH.div_
    [ renderWalletWidgetSlot
    , RU.renderHeroSection
    , RU.renderProfessionalServicesSection
    , RU.renderPoolOverviewSection
    , RU.renderCexplorerPoolGraphSection
    , RU.renderFooterSection
    , RU.renderFabFlower
    , RU.renderToasts $ getToast <$> s.toasts -- must be last to show up in front.
    ]

renderWalletWidgetSlot ::
  forall m.
  MonadAff m =>
  MonadAsk Env m =>
  MonadCIP30 m =>
  MonadStore Store.Action Store.Store m =>
  H.ComponentHTML Action Slots m
renderWalletWidgetSlot = HH.slot NavBar.navbarProxy unit NavBar.component unit HandleNavBarOutput


txBuildSuccessToast ∷ { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txBuildSuccessToast = { remainingSeconds: 5, alertType: "info alert-soft", message: "Transaction built successfully. Please review and sign the transaction." }
txBuildFailedToast ∷ String → { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txBuildFailedToast e = { remainingSeconds: 5, alertType: "error", message: "Transaction building failed: " <> e }


txSubmitSuccessToast ∷  { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txSubmitSuccessToast  = { remainingSeconds: 5, alertType: "info", message: "Transaction signed and submitted successfully" }

txSubmitFailedToast ∷ String → { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txSubmitFailedToast e = { remainingSeconds: 5, alertType: "error", message: "Transaction submission failed: " <> e }

txConfirmedSuccessToast ∷ String → { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txConfirmedSuccessToast txId = { remainingSeconds: 5, alertType: "success", message: "Transaction confirmed: " <> txId }

txConfirmedFailedToast ∷ String → { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txConfirmedFailedToast txId = { remainingSeconds: 5, alertType: "error", message: "Transaction confirmation failed: " <> txId }