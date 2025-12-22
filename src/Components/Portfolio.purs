module Components.Portfolio where

import Prelude
import Data.Maybe (Maybe(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Type.Proxy (Proxy(..))

--------------------------------------------------------------------------------
-- * Component Interface
--------------------------------------------------------------------------------
type Slot
  = H.Slot Query Output Unit

portfolioProxy = Proxy :: Proxy "portfolioWidget"

type Input
  = {}

type State
  = {}

data Query :: forall k. k -> Type
data Query a
  = Query

data Output
  = NavigateToHome

data Action
  = Initialize

component ::
  forall m.
  H.Component Query Input Output m
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
initialState _ = {}

handleAction ::
  forall m.
  Action -> H.HalogenM State Action () Output m Unit
handleAction action = case action of
  Initialize -> pure unit

--------------------------------------------------------------------------------
-- * Component Rendering
--------------------------------------------------------------------------------
render ::
  forall m.
  State -> H.ComponentHTML Action () m
render _ =
  HH.div_
    [ renderSecurityAuditsSection
    ]

--------------------------------------------------------------------------------
-- * Security Audits Section
--------------------------------------------------------------------------------
renderSecurityAuditsSection :: forall w i. HH.HTML w i
renderSecurityAuditsSection =
  HH.section
    [ HP.id "security-audits"
    , HP.classes [ HH.ClassName "w-full min-h-screen max-w-6xl mx-auto px-4 sm:px-6 py-8 sm:py-12" ]
    ]
    [ HH.div [ HP.classes [ HH.ClassName "text-center mb-6 sm:mb-8" ] ]
        [ HH.h2 [ HP.classes [ HH.ClassName "text-2xl sm:text-3xl md:text-4xl font-bold" ] ]
            [ HH.text "Security Audits" ]
        , HH.p [ HP.classes [ HH.ClassName "opacity-80 mt-2 text-sm sm:text-base px-2" ] ]
            [ HH.text "We take security seriously. All our projects undergo rigorous security audits to ensure the highest standards of safety and reliability."
            ]
        ]
    , HH.div [ HP.classes [ HH.ClassName "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6" ] ]
        [ auditCard
            "Hydra Pay Audit Report"
            "Comprehensive security audit of the Hydra Pay protocol"
            "/doc/hydra-pay-audit-report-signed.pdf"
        ]
    ]
  where
  auditCard :: forall w' i'. String -> String -> String -> HH.HTML w' i'
  auditCard title description pdfPath =
    HH.div [ HP.classes [ HH.ClassName "card bg-base-200 shadow-lg hover:shadow-xl transition-shadow" ] ]
      [ HH.div [ HP.classes [ HH.ClassName "card-body" ] ]
          [ HH.h3 [ HP.classes [ HH.ClassName "card-title text-lg sm:text-xl" ] ]
              [ HH.text title ]
          , HH.p [ HP.classes [ HH.ClassName "opacity-90 mb-4 text-sm sm:text-base" ] ]
              [ HH.text description ]
          , HH.a
              [ HP.classes [ HH.ClassName "btn btn-primary btn-sm sm:btn-md w-full sm:w-auto" ]
              , HP.href pdfPath
              , HP.target "_blank"
              , HP.rel "noopener noreferrer"
              ]
              [ HH.text "View Audit Report" ]
          ]
      ]
