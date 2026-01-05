module Components.About where

import Prelude

import Components.HTML.RenderUtils.App (renderBackButton)
import Data.Maybe (Maybe(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Svg.Attributes as SA
import Halogen.Svg.Attributes.Color (Color(..))
import Halogen.Svg.Attributes.StrokeLineCap (StrokeLineCap(..))
import Halogen.Svg.Attributes.StrokeLineJoin (StrokeLineJoin(..))
import Halogen.Svg.Elements as SE
import Type.Proxy (Proxy(..))

--------------------------------------------------------------------------------
-- * Component Interface
--------------------------------------------------------------------------------
type Slot
  = H.Slot Query Output Unit

aboutProxy = Proxy :: Proxy "aboutWidget"

type Input
  = {}

type State
  = {}

data Query :: forall k. k -> Type
data Query a
  = Query

data Output
  = NavigateToHome
  | NavigateToPortfolio

data Action
  = Initialize
  | GoHome
  | GoToPortfolio

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
  GoHome -> H.raise NavigateToHome
  GoToPortfolio -> H.raise NavigateToPortfolio

--------------------------------------------------------------------------------
-- * Component Rendering
--------------------------------------------------------------------------------
render ::
  forall m.
  State -> H.ComponentHTML Action () m
render _ =
  HH.div [ HP.classes [ HH.ClassName "w-full min-h-screen" ] ]
    [ renderHeroSection
    , renderFoundersSection
    , renderMissionSection
    , renderTimelineSection
    , renderValuesSection
    , renderPortfolioCTA
    , renderBackButton GoHome
    ]

--------------------------------------------------------------------------------
-- * Hero Section
--------------------------------------------------------------------------------
renderHeroSection :: forall w i. HH.HTML w i
renderHeroSection =
  HH.section
    [ HP.classes [ HH.ClassName "hero min-h-[60vh] bg-gradient-to-br from-base-300 via-base-200 to-base-100 relative overflow-hidden" ] ]
    [ -- Decorative background elements
      HH.div [ HP.classes [ HH.ClassName "absolute inset-0 opacity-10" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "absolute top-20 left-10 w-72 h-72 bg-primary rounded-full blur-3xl" ] ] []
        , HH.div [ HP.classes [ HH.ClassName "absolute bottom-10 right-20 w-96 h-96 bg-secondary rounded-full blur-3xl" ] ] []
        , HH.div [ HP.classes [ HH.ClassName "absolute top-40 right-40 w-48 h-48 bg-accent rounded-full blur-2xl" ] ] []
        ]
    , HH.div [ HP.classes [ HH.ClassName "hero-content text-center relative z-10" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "max-w-4xl" ] ]
            [ HH.h1 [ HP.classes [ HH.ClassName "text-5xl md:text-7xl font-black bg-gradient-to-r from-primary via-info to-accent bg-clip-text text-transparent animate-pulse" ] ]
                [ HH.text "About Us" ]
            , HH.p [ HP.classes [ HH.ClassName "py-6 text-xl md:text-2xl opacity-80 max-w-2xl mx-auto" ] ]
                [ HH.text "Twin brothers united by a shared passion for crypto, cypherpunk ideals, and libertarian values. Building decentralized solutions that empower individuals and protect privacy." ]

            ]
        ]
    ]

--------------------------------------------------------------------------------
-- * Founders Section
--------------------------------------------------------------------------------
renderFoundersSection :: forall w i. HH.HTML w i
renderFoundersSection =
  HH.section
    [ HP.id "founders"
    , HP.classes [ HH.ClassName "w-full max-w-7xl mx-auto px-4 sm:px-6 py-16 sm:py-24" ]
    ]
    [ HH.div [ HP.classes [ HH.ClassName "text-center mb-12" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "badge badge-primary badge-lg mb-4" ] ] [ HH.text "Our Team" ]
        , HH.h2 [ HP.classes [ HH.ClassName "text-4xl md:text-5xl font-bold" ] ] [ HH.text "Co-Founders" ]
        , HH.div [ HP.classes [ HH.ClassName "divider divider-info max-w-xs mx-auto" ] ] []
        ]
    , HH.div [ HP.classes [ HH.ClassName "grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12" ] ]
        [ founderCard
            { name: "Marius Georgescu"
            , role: "Co-Founder & Lead Developer"
            , linkedIn: "https://www.linkedin.com/in/georgescumarius/"
            , avatar: "./images/team/Marius.jpeg"
            , description: "Dr.Eng. & Solution Architect with 10+ years in banking, fintech, and telecom. Passionate about Web3, blockchain, and decentralized systems."
            , skills: [ "Business Analysis",  "Solution Architecture" , "Software Development", "Deployment and Infrastructure" ]
            , achievements: 
                [ "🎓 PhD in Engineering"
                , "🎓 Emurgo Academy - Cardano Solution Architect"
                , "🎓 Plutus Pioneer Program - 1st cohort"
                , "🏆 Multiple Project Catalyst proposals delivered"
                ]
            }
        , founderCard
            { name: "Andrei Georgescu"
            , role: "Co-Founder & Lead Developer"
            , linkedIn: "https://www.linkedin.com/in/andreigeorgescoo/"
            , avatar: "./images/team/Andrei.png"
            , description: "Machine Learning and Computer Vision engineer with extensive experience in distributed systems, image processing pipelines, and game engine development."
            , skills: [ "Machine Learning", "Computer Vision", "Deep Learning", "Distributed Systems", "Game Development" ]
            , achievements:
                [ "🎓 Master's Degree in Artificial Intelligence"
                , "📜 3 patent publications"
                , "🏆 10+ years of experience in machine learning and computer vision"
                ]
            }
        ]
    ]
  where
  founderCard :: forall w' i'. { name :: String, role :: String, linkedIn :: String, avatar :: String, description :: String, skills :: Array String, achievements :: Array String } -> HH.HTML w' i'
  founderCard founder =
    HH.div [ HP.classes [ HH.ClassName "card relative bg-gradient-to-br from-base-200 to-base-300 shadow-xl shadow-info/10 -translate-y-1 lg:shadow-2xl lg:shadow-base-300 lg:translate-y-0 lg:hover:shadow-info/20 lg:hover:-translate-y-2 transition-all duration-500 group active:-translate-y-2 active:shadow-info/20" ] ]
      [ -- Glowing border effect (subtle on mobile, full on lg hover)
        HH.div [ HP.classes [ HH.ClassName "absolute inset-0 rounded-2xl bg-gradient-to-r from-info/0 via-info/20 to-secondary/0 opacity-30 lg:opacity-0 lg:group-hover:opacity-100 transition-opacity duration-500 blur-xl" ] ] []
      , HH.div [ HP.classes [ HH.ClassName "card-body relative z-10" ] ]
          [ -- Avatar & Name Section
            HH.div [ HP.classes [ HH.ClassName "flex flex-col sm:flex-row items-center gap-6 mb-6" ] ]
              [ -- Avatar with ring
                HH.div [ HP.classes [ HH.ClassName "avatar" ] ]
                  [ HH.div [ HP.classes [ HH.ClassName "w-24 h-24 rounded-full ring ring-info ring-offset-base-100 ring-offset-4 overflow-hidden" ] ]
                      [ HH.img 
                          [ HP.src founder.avatar
                          , HP.alt founder.name
                          , HP.classes [ HH.ClassName "w-full h-full object-cover" ]
                          ]
                      ]
                  ]
              , HH.div [ HP.classes [ HH.ClassName "text-center sm:text-left" ] ]
                  [ HH.h3 [ HP.classes [ HH.ClassName "text-2xl font-bold" ] ] [ HH.text founder.name ]
                  , HH.p [ HP.classes [ HH.ClassName "text-info font-medium" ] ] [ HH.text founder.role ]
                  ]
              ]
          , -- Description
            HH.p [ HP.classes [ HH.ClassName "opacity-80 mb-6 leading-relaxed" ] ] [ HH.text founder.description ]
          , -- Skills
            HH.div [ HP.classes [ HH.ClassName "mb-6" ] ]
              [ HH.h4 [ HP.classes [ HH.ClassName "text-sm font-semibold opacity-60 mb-3" ] ] [ HH.text "EXPERTISE" ]
              , HH.div [ HP.classes [ HH.ClassName "flex flex-wrap gap-2" ] ]
                  (founder.skills <#> \skill -> 
                    HH.span [ HP.classes [ HH.ClassName "badge badge-outline badge-info badge-sm" ] ] [ HH.text skill ]
                  )
              ]
          , -- Achievements
            HH.div [ HP.classes [ HH.ClassName "mb-6" ] ]
              [ HH.h4 [ HP.classes [ HH.ClassName "text-sm font-semibold opacity-60 mb-3" ] ] [ HH.text "ACHIEVEMENTS" ]
              , HH.ul [ HP.classes [ HH.ClassName "space-y-2" ] ]
                  (founder.achievements <#> \achievement ->
                    HH.li [ HP.classes [ HH.ClassName "flex items-center gap-2 text-sm" ] ]
                      [ HH.text achievement ]
                  )
              ]
          , -- LinkedIn Button
            HH.div [ HP.classes [ HH.ClassName "card-actions justify-center mt-auto" ] ]
              [ HH.a
                  [ HP.classes [ HH.ClassName "btn btn-info btn-outline gap-2 group-hover:btn-info group-hover:text-info-content transition-all" ]
                  , HP.href founder.linkedIn
                  , HP.target "_blank"
                  ]
                  [ linkedInIcon
                  , HH.text "Connect on LinkedIn"
                  ]
              ]
          ]
      ]

  linkedInIcon :: forall w' i'. HH.HTML w' i'
  linkedInIcon =
    SE.svg
      [ SA.class_ $ HH.ClassName "h-5 w-5"
      , SA.fill (Named "currentColor")
      , SA.viewBox 0.0 0.0 24.0 24.0
      ]
      [ SE.path
          [ HP.attr (HH.AttrName "d") "M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"
          ]
      ]

--------------------------------------------------------------------------------
-- * Mission Section
--------------------------------------------------------------------------------
renderMissionSection :: forall w i. HH.HTML w i
renderMissionSection =
  HH.section
    [ HP.classes [ HH.ClassName "w-full bg-base-200 py-16 sm:py-24" ] ]
    [ HH.div [ HP.classes [ HH.ClassName "max-w-6xl mx-auto px-4 sm:px-6" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "grid grid-cols-1 lg:grid-cols-2 gap-12 items-center" ] ]
            [ HH.div_
                [ HH.div [ HP.classes [ HH.ClassName "badge badge-primary badge-lg mb-4" ] ] [ HH.text "Our Purpose" ]
                , HH.h2 [ HP.classes [ HH.ClassName "text-4xl md:text-5xl font-bold mb-6" ] ] [ HH.text "Our Mission" ]
                , HH.p [ HP.classes [ HH.ClassName "text-lg opacity-80 leading-relaxed mb-6" ] ]
                    [ HH.text "We believe in Cardano's vision of a decentralized, secure, and sustainable blockchain ecosystem. Our mission is to contribute to this vision by providing top-tier infrastructure, development services, and community support." ]
                , HH.p [ HP.classes [ HH.ClassName "text-lg opacity-80 leading-relaxed" ] ]
                    [ HH.text "Every line of code we write, every smart contract we deploy, and every block we produce brings us closer to a more equitable financial future." ]
                ]
            , HH.div [ HP.classes [ HH.ClassName "grid grid-cols-2 gap-4" ] ]
                [ missionStat "🔗" "Decentralization" "Strengthening the network"
                , missionStat "🛡️" "Security" "Battle-tested solutions"
                , missionStat "⚡" "Performance" "Optimized for efficiency"
                , missionStat "🌱" "Sustainability" "Long-term thinking"
                ]
            ]
        ]
    ]
  where
  missionStat :: forall w' i'. String -> String -> String -> HH.HTML w' i'
  missionStat emoji title subtitle =
    HH.div [ HP.classes [ HH.ClassName "card bg-base-100 shadow-lg hover:shadow-xl transition-shadow" ] ]
      [ HH.div [ HP.classes [ HH.ClassName "card-body items-center text-center p-6" ] ]
          [ HH.span [ HP.classes [ HH.ClassName "text-4xl mb-2" ] ] [ HH.text emoji ]
          , HH.h3 [ HP.classes [ HH.ClassName "font-bold" ] ] [ HH.text title ]
          , HH.p [ HP.classes [ HH.ClassName "text-sm opacity-70" ] ] [ HH.text subtitle ]
          ]
      ]

--------------------------------------------------------------------------------
-- * Timeline Section
--------------------------------------------------------------------------------
renderTimelineSection :: forall w i. HH.HTML w i
renderTimelineSection =
  HH.section
    [ HP.classes [ HH.ClassName "w-full max-w-4xl mx-auto px-4 sm:px-6 py-16 sm:py-24" ] ]
    [ HH.div [ HP.classes [ HH.ClassName "text-center mb-12" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "badge badge-primary badge-lg mb-4" ] ] [ HH.text "Our Story" ]
        , HH.h2 [ HP.classes [ HH.ClassName "text-4xl md:text-5xl font-bold" ] ] [ HH.text "Our Journey" ]
        ]
    , HH.ul [ HP.classes [ HH.ClassName "timeline timeline-snap-icon timeline-vertical max-md:timeline-compact" ] ]
        [ timelineItem true "2020" "Discovered Cardano" "Fell in love with Cardano's scientific approach, peer-reviewed research, and vision for a decentralized future."
        , timelineItem false "2021" "Plutus Pioneers" "Joined the first cohort of the Plutus Pioneer Program, mastering smart contract development on Cardano."
        , timelineItem true "2023" "E7D Stake Pool" "Launched our stake pool E7D, contributing to network decentralization and security."
        , timelineItem false "2024" "Project Catalyst" "Started participating in Project Catalyst and successfully delivered 3 funded projects to the community."
        , timelineItem true "2025" "ENTANGLED Labs" "Officially formed ENTANGLED Labs to scale our impact and bring more innovation to Web3."
        ]
    ]
  where
  timelineItem :: forall w' i'. Boolean -> String -> String -> String -> HH.HTML w' i'
  timelineItem isStart year title description =
    HH.li_
      [ HH.div [ HP.classes [ HH.ClassName "timeline-middle" ] ]
          [ HH.div [ HP.classes [ HH.ClassName "w-5 h-5 rounded-full bg-info" ] ] []
          ]
      , HH.div [ HP.classes [ HH.ClassName $ (if isStart then "timeline-start" else "timeline-end") <> " timeline-box bg-base-200 shadow-lg hover:shadow-xl transition-shadow mb-10" ] ]
          [ HH.div [ HP.classes [ HH.ClassName "badge badge-info badge-sm mb-2" ] ] [ HH.text year ]
          , HH.h3 [ HP.classes [ HH.ClassName "font-bold text-lg" ] ] [ HH.text title ]
          , HH.p [ HP.classes [ HH.ClassName "opacity-80 text-sm" ] ] [ HH.text description ]
          ]
      , HH.hr_
      ]

--------------------------------------------------------------------------------
-- * Values Section
--------------------------------------------------------------------------------
renderValuesSection :: forall w i. HH.HTML w i
renderValuesSection =
  HH.section
    [ HP.classes [ HH.ClassName "w-full bg-gradient-to-b from-base-100 to-base-200 py-16 sm:py-24" ] ]
    [ HH.div [ HP.classes [ HH.ClassName "max-w-6xl mx-auto px-4 sm:px-6" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "text-center mb-12" ] ]
            [ HH.div [ HP.classes [ HH.ClassName "badge badge-primary badge-lg mb-4" ] ] [ HH.text "Our Values" ]
            , HH.h2 [ HP.classes [ HH.ClassName "text-4xl md:text-5xl font-bold" ] ] [ HH.text "What Drives Us" ]
            ]
        , HH.div [ HP.classes [ HH.ClassName "grid grid-cols-1 md:grid-cols-3 gap-6" ] ]
            [ valueCard "💎" "Transparency" "Open source, open communication. We believe in building trust through transparency in everything we do."
            , valueCard "🎯" "Excellence" "We don't cut corners. Every project receives our full attention and commitment to quality."
            , valueCard "🤝" "Community" "Cardano is about community. We actively contribute, share knowledge, and support fellow builders."
            ]
        ]
    ]
  where
  valueCard :: forall w' i'. String -> String -> String -> HH.HTML w' i'
  valueCard emoji title description =
    HH.div [ HP.classes [ HH.ClassName "card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 hover:-translate-y-1" ] ]
      [ HH.div [ HP.classes [ HH.ClassName "card-body text-center" ] ]
          [ HH.div [ HP.classes [ HH.ClassName "text-5xl mb-4" ] ] [ HH.text emoji ]
          , HH.h3 [ HP.classes [ HH.ClassName "card-title justify-center text-xl" ] ] [ HH.text title ]
          , HH.p [ HP.classes [ HH.ClassName "opacity-80" ] ] [ HH.text description ]
          ]
      ]

--------------------------------------------------------------------------------
-- * Portfolio CTA Section
--------------------------------------------------------------------------------
renderPortfolioCTA :: forall w. HH.HTML w Action
renderPortfolioCTA =
  HH.section
    [ HP.classes [ HH.ClassName "w-full py-16 sm:py-24 bg-gradient-to-r from-primary/10 via-info/10 to-accent/10" ] ]
    [ HH.div [ HP.classes [ HH.ClassName "max-w-4xl mx-auto px-4 sm:px-6 text-center" ] ]
        [ HH.div [ HP.classes [ HH.ClassName "card bg-base-100 shadow-2xl" ] ]
            [ HH.div [ HP.classes [ HH.ClassName "card-body py-12" ] ]
                [ HH.div [ HP.classes [ HH.ClassName "text-6xl mb-4" ] ] [ HH.text "🚀" ]
                , HH.h2 [ HP.classes [ HH.ClassName "text-3xl md:text-4xl font-bold mb-4" ] ] 
                    [ HH.text "Want to see our work?" ]
                , HH.p [ HP.classes [ HH.ClassName "text-lg opacity-80 mb-8 max-w-2xl mx-auto" ] ]
                    [ HH.text "Explore our Project Catalyst proposals and the innovative solutions we've delivered to the Cardano community." ]
                , HH.button
                    [ HP.classes [ HH.ClassName "btn btn-accent btn-lg gap-2" ]
                    , HE.onClick \_ -> GoToPortfolio
                    ]
                    [ HH.text "Check out our portfolio"
                    , SE.svg
                        [ SA.class_ $ HH.ClassName "h-5 w-5"
                        , SA.fill NoColor
                        , SA.viewBox 0.0 0.0 24.0 24.0
                        ]
                        [ SE.path
                            [ SA.strokeLineCap LineCapRound
                            , SA.strokeLineJoin LineJoinRound
                            , SA.strokeWidth 2.0
                            , HP.attr (HH.AttrName "stroke") "currentColor"
                            , HP.attr (HH.AttrName "d") "M13 7l5 5m0 0l-5 5m5-5H6"
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]

