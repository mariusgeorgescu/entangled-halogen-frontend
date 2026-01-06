module Components.Home where

import Prelude
import App.Utils (scrollToTop)
import AppEnv (Env)
import AppTypes (DelegationAction(..))
import Cardano.Capabilities.Wallet.MonadCIP30 (class MonadCIP30)
import Cardano.Capabilities (PoolInfo, class MonadCardanoQuery, fetchPoolInfo, class MonadInteraction, buildTransaction, signTransaction, submitTransaction)
import Cardano.Wallet.Cip30 as Cardano.Wallet.Cip30
import Components.HTML.RenderUtils.App (renderAccentButton, renderFabFlower, renderFooterSection, renderHeroSection, renderPoolOverviewSection, renderPrimaryButton, renderProfessionalServicesSection, renderSecondaryButton, renderToasts) as RU
import Components.NavBar as NavBar
import Components.Portfolio as Portfolio
import Components.About as About
import Control.Monad.Reader.Class (class MonadAsk, ask, asks)
import Control.Monad.Rec.Class (forever)
import Data.Array (cons, filter)
import Data.DateTime.Instant (unInstant)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Time.Duration (Milliseconds(..))
import Data.Tuple (Tuple(..))
import Effect.Aff (error, throwError)
import Effect.Aff as Aff
import Effect.Aff.Class (class MonadAff)
import Effect.Now (now)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.Store.Monad (class MonadStore)
import Halogen.Subscription as HS
import Store as Store
import Effect.Console (log) as Console

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

parseDelegationAction ::
  forall m.
  MonadAff m =>
  String -> Env -> m DelegationAction
parseDelegationAction userAction env = case userAction of
  "DelegateToPool" -> pure (PoolDelegation { poolId: env.myPoolId })
  "DelegateToDRep" -> pure (DRepDelegation { dRepHash: env.myDRepHash })
  "DelegateToPoolAndDRep" -> pure (PoolAndDRepDelegation { poolId: env.myPoolId, dRepHash: env.myDRepHash })
  _ -> H.liftAff $ throwError (error "Invalid delegation action")

--------------------------------------------------------------------------------
-- * Component Definition
--------------------------------------------------------------------------------
type Slots
  = ( navbarWidget :: NavBar.Slot
    , portfolioWidget :: Portfolio.Slot
    , aboutWidget :: About.Slot
    )

data Page
  = MainPage
  | PortfolioPage
  | AboutPage

derive instance eqValue :: Eq Page

type Input
  = {
    }

type State
  = { toasts :: Array Toast
    , currentPage :: Page
    , currentTime :: Number
    , poolInfo :: Maybe PoolInfo
    , myPoolId :: String
    }

data Action
  = Initialize
  | ChangePage Page
  | HandleNavBarOutput NavBar.Output
  | HandlePortfolioOutput Portfolio.Output
  | HandleAboutOutput About.Output
  | SubmitTransaction String String
  | SignTransaction Cardano.Wallet.Cip30.Api String
  | StartEarningRewardsButton
  | LetUsBeYourDRepButton
  | BothButton
  | Tick
  | FetchPoolInfo
  | PoolInfoReceived (Either String PoolInfo)

component ::
  forall query output m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadStore Store.Action Store.Store m =>
  MonadAsk Env m =>
  MonadInteraction m =>
  MonadCardanoQuery m =>
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
initialState _i = { currentPage: MainPage, toasts: [], currentTime: 0.0, poolInfo: Nothing, myPoolId: "" }

handleAction ::
  forall output m.
  MonadAff m =>
  MonadCIP30 m =>
  MonadStore Store.Action Store.Store m =>
  MonadAsk Env m =>
  MonadInteraction m =>
  MonadCardanoQuery m =>
  Action -> H.HalogenM State Action Slots output m Unit
handleAction action = case action of
  Initialize -> do
    -- Store poolId from environment in state
    env <- ask
    H.modify_ _ { myPoolId = env.myPoolId }
    -- Subscribe to get the current time at a regular interval
    void $ H.subscribe =<< createTimerEmitter Tick
    -- Fetch pool info
    handleAction FetchPoolInfo
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
  FetchPoolInfo -> do
    env <- ask
    result <- fetchPoolInfo env env.myPoolId
    case result of
      Right poolInfo -> do
        handleAction $ PoolInfoReceived $ Right poolInfo
      Left err -> do
        H.liftEffect $ Console.log $ "Failed to fetch pool info: " <> err
        handleAction $ PoolInfoReceived $ Left err
  PoolInfoReceived (Right poolInfo) -> do
    H.modify_ _ { poolInfo = Just poolInfo }
    H.liftEffect $ Console.log $ "Pool info received successfully"
  PoolInfoReceived (Left err) -> do
    H.liftEffect $ Console.log $ "Failed to fetch pool info: " <> err
  -- Don't show error to user, just log it
  Tick -> do
    ct <- unwrap <<< unInstant <$> H.liftEffect now
    ts <- H.gets _.toasts
    let
      newTs = clearToasts <<< decrementToats $ ts
    H.modify_ _ { currentTime = ct, toasts = newTs }
  SignTransaction api unsignedTxCbor -> do
    signedTxResult <- signTransaction api unsignedTxCbor
    case signedTxResult of
      Right signedTxCbor -> do
        H.modify_ \s -> s { toasts = txSubmitSuccessToast `cons` s.toasts }
        handleAction (SubmitTransaction unsignedTxCbor signedTxCbor)
      Left err -> do
        H.modify_ \s -> s { toasts = txSubmitFailedToast err `cons` s.toasts }
    pure unit
  SubmitTransaction unsignedTxCbor signedTx -> do
    env <- ask
    submitResult <- submitTransaction env unsignedTxCbor signedTx
    case submitResult of
      Right txId -> do
        H.modify_ \s -> s { toasts = txConfirmedSuccessToast txId `cons` s.toasts }
      Left err -> do
        H.modify_ \s -> s { toasts = txConfirmedFailedToast err `cons` s.toasts }
    H.liftEffect $ Console.log $ show submitResult
    pure unit
  HandleNavBarOutput navbarout -> case navbarout of
    NavBar.HomeEvent -> do
      handleAction (ChangePage MainPage)
    NavBar.AboutEvent -> do
      handleAction (ChangePage AboutPage)
    NavBar.BuildTransactionEvent userAction api -> do
      env <- ask
      delegationAction <- parseDelegationAction userAction env
      buildResult <- buildTransaction env api delegationAction
      H.liftEffect $ Console.log $ show buildResult
      case buildResult of
        Right txCbor -> do
          H.modify_ \s -> s { toasts = txBuildSuccessToast `cons` s.toasts }
          handleAction (SignTransaction api txCbor)
        -- Left "GYBuildTxException GYBuildTxNoSuitableCollateral" -> do
        --   H.modify_ \s -> s { toasts = txBuildFailedToast "Please first set collateral in your wallet !" `cons` s.toasts }
        Left err -> do
          H.modify_ \s -> s { toasts = txBuildFailedToast err `cons` s.toasts }
      pure unit
    NavBar.WalletConnectEvent -> pure unit
    NavBar.InvalidNetworkEvent currentNetwork -> do
      cardanoNetwork <- asks (_.allowedNetworkId)
      let
        newToast = { remainingSeconds: 5, alertType: "error", message: "You are connected to the " <> show currentNetwork <> " network, but the app is configured to use the " <> show cardanoNetwork <> " network" }
      H.modify_ \s -> s { toasts = newToast `cons` s.toasts }
  StartEarningRewardsButton -> do
    mApi <- H.query NavBar.navbarProxy unit (NavBar.GetWalletApi identity)
    case mApi of
      Just (Just api) -> do
        handleAction (HandleNavBarOutput (NavBar.BuildTransactionEvent "DelegateToPool" api))
      _ -> H.modify_ \s -> s { toasts = walletNotConnectedToast `cons` s.toasts }
  LetUsBeYourDRepButton -> do
    mApi <- H.query NavBar.navbarProxy unit (NavBar.GetWalletApi identity)
    case mApi of
      Just (Just api) -> do
        handleAction (HandleNavBarOutput (NavBar.BuildTransactionEvent "DelegateToPool" api))
      _ -> H.modify_ \s -> s { toasts = walletNotConnectedToast `cons` s.toasts }
  BothButton -> do
    mApi <- H.query NavBar.navbarProxy unit (NavBar.GetWalletApi identity)
    case mApi of
      Just (Just api) -> do
        handleAction (HandleNavBarOutput (NavBar.BuildTransactionEvent "DelegateToPool" api))
      _ -> H.modify_ \s -> s { toasts = walletNotConnectedToast `cons` s.toasts }
  ChangePage page -> do
    H.liftEffect $ scrollToTop
    H.modify_ _ { currentPage = page }
  HandlePortfolioOutput portfolioout -> case portfolioout of
    Portfolio.NavigateToHome -> handleAction (ChangePage MainPage)
  HandleAboutOutput aboutout -> case aboutout of
    About.NavigateToHome -> handleAction (ChangePage MainPage)
    About.NavigateToPortfolio -> handleAction (ChangePage PortfolioPage)

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
    , renderBodyContent s
    , RU.renderFooterSection { onAboutClick: ChangePage AboutPage, onPortfolioClick: ChangePage PortfolioPage }
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

renderBodyContent ::
  forall m.
  MonadAff m =>
  MonadAsk Env m =>
  MonadCIP30 m =>
  MonadStore Store.Action Store.Store m =>
  State -> H.ComponentHTML Action Slots m
renderBodyContent s = case s.currentPage of
  MainPage ->
    HH.div_
      [ RU.renderHeroSection heroButtonsList
      , RU.renderProfessionalServicesSection professionalServicesButtonsList
      , RU.renderPoolOverviewSection s.poolInfo
      , renderLiveProjectsSection
      ]
  PortfolioPage -> renderPortfolioWidgetSlot
  AboutPage -> renderAboutWidgetSlot

renderPortfolioWidgetSlot ::
  forall m.
  H.ComponentHTML Action Slots m
renderPortfolioWidgetSlot = HH.slot Portfolio.portfolioProxy unit Portfolio.component {} HandlePortfolioOutput

renderAboutWidgetSlot ::
  forall m.
  H.ComponentHTML Action Slots m
renderAboutWidgetSlot = HH.slot About.aboutProxy unit About.component {} HandleAboutOutput

heroButtonsList :: forall w. Array (HH.HTML w Action)
heroButtonsList =
  [ RU.renderSecondaryButton "Start Earning Rewards" StartEarningRewardsButton
  , RU.renderSecondaryButton "Delegate Your Vote" LetUsBeYourDRepButton
  , RU.renderPrimaryButton "Stake & Vote" BothButton
  ]

professionalServicesButtonsList :: forall w. Array (HH.HTML w Action)
professionalServicesButtonsList =
  [ RU.renderAccentButton "About Us" (ChangePage AboutPage)
  , RU.renderAccentButton "Check out our portfolio" (ChangePage PortfolioPage)
  ]

--------------------------------------------------------------------------------
-- * Live Projects Section
--------------------------------------------------------------------------------
renderLiveProjectsSection :: forall w i. HH.HTML w i
renderLiveProjectsSection =
  HH.section
    [ HP.id "live-projects"
    , HP.classes [ HH.ClassName "w-full max-w-6xl mx-auto px-4 sm:px-6 py-8 sm:py-12" ]
    ]
    [ HH.div [ HP.classes [ HH.ClassName "text-center mb-6 sm:mb-8" ] ]
        [ HH.h2 [ HP.classes [ HH.ClassName "text-2xl sm:text-3xl md:text-4xl font-bold" ] ]
            [ HH.text "Live Projects" ]
        , HH.p [ HP.classes [ HH.ClassName "opacity-80 mt-2 text-sm sm:text-base px-2" ] ]
            [ HH.text "Explore some of our projects."
            ]
        ]
    , HH.div [ HP.classes [ HH.ClassName "grid grid-cols-2 md:grid-cols-4 gap-4 sm:gap-6" ] ]
        [ liveProjectCard
            "Tokenized BJJ Belts"
            "./images/logos/bjj-logo-gradient.svg"
            "https://www.bjj-belts.org"
        , liveProjectCard
            "Raffleize Art"
            "./images/logos/raffleize_raffle.png"
            "https://www.raffleize.art"
        , liveProjectCard
            "Crypto Portfolio Tracker"
            "./images/logos/dashboard.png"
            "https://www.crypto-portofolio.com"
        , liveProjectCard
            "Cardano Ticker Device"
            "./images/logos/cardanotickerbadgewobg.png"
            "https://github.com/en7angled/CardanoTicker/tree/main"
        ]
    ]
  where
  liveProjectCard :: forall w' i'. String -> String -> String -> HH.HTML w' i'
  liveProjectCard name logoPath projectUrl =
    HH.a
      [ HP.classes [ HH.ClassName "card relative bg-gradient-to-br from-base-200 to-base-300 shadow-xl shadow-info/10 lg:hover:shadow-info/20 lg:hover:-translate-y-2 transition-all duration-500 cursor-pointer group active:-translate-y-2 active:shadow-info/20" ]
      , HP.href projectUrl
      , HP.target "_blank"
      , HP.rel "noopener noreferrer"
      ]
      [ -- Glowing border effect (subtle on mobile, full on lg hover)
        HH.div [ HP.classes [ HH.ClassName "absolute inset-0 rounded-2xl bg-gradient-to-r from-info/0 via-info/20 to-secondary/0 opacity-30 lg:opacity-0 lg:group-hover:opacity-100 transition-opacity duration-500 blur-xl" ] ] []
      , HH.figure [ HP.classes [ HH.ClassName "px-6 pt-6 relative z-10" ] ]
          [ HH.img
              [ HP.src logoPath
              , HP.alt name
              , HP.classes [ HH.ClassName "rounded-lg w-20 h-20 sm:w-24 sm:h-24 object-contain group-hover:scale-110 transition-transform" ]
              ]
          ]
      , HH.div [ HP.classes [ HH.ClassName "card-body items-center text-center py-4 relative z-10" ] ]
          [ HH.h3 [ HP.classes [ HH.ClassName "card-title text-sm sm:text-base md:text-lg" ] ]
              [ HH.text name ]
          ]
      ]

txBuildSuccessToast ∷ { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txBuildSuccessToast = { remainingSeconds: 5, alertType: "info alert-dash", message: "Transaction built successfully. Please review and sign the transaction." }

txBuildFailedToast ∷ String → { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txBuildFailedToast e = { remainingSeconds: 5, alertType: "error", message: "Transaction building failed: " <> e }

txSubmitSuccessToast ∷ { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txSubmitSuccessToast = { remainingSeconds: 5, alertType: "info", message: "Transaction signed and submitted successfully" }

txSubmitFailedToast ∷ String → { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txSubmitFailedToast e = { remainingSeconds: 5, alertType: "error", message: "Transaction submission failed: " <> e }

txConfirmedSuccessToast ∷ String → { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txConfirmedSuccessToast txId = { remainingSeconds: 5, alertType: "success", message: "Transaction confirmed: " <> txId }

txConfirmedFailedToast ∷ String → { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
txConfirmedFailedToast txId = { remainingSeconds: 5, alertType: "error", message: "Transaction confirmation failed: " <> txId }

walletNotConnectedToast ∷ { alertType ∷ String, message ∷ String, remainingSeconds ∷ Int }
walletNotConnectedToast = { remainingSeconds: 5, alertType: "info", message: "Please connect your wallet for this action" }
