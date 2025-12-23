module App.Utils
  ( module Halogen.DaisyUI.Utils
  , lovelaceToAda
  ) where

import Prelude ((/))

import Halogen.DaisyUI.Utils (enumerate, formatNumberFromStr, printPOSIX, printPOSIX', printPOSIX'', scrollByXY, scrollToTop, shortString, stringLimitBy, trimQuotes)

-- | Convert lovelace to ADA (1 ADA = 1,000,000 lovelace)
lovelaceToAda :: Number -> Number
lovelaceToAda n = n / 1_000_000.0
