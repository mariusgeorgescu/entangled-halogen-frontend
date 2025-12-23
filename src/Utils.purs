module App.Utils
  ( lovelaceToAda
  , scrollToTop
  ) where

import Prelude ((/), Unit)
import Effect (Effect)
import Halogen.DaisyUI.Utils (scrollToTop) as DaisyUI

-- | Convert lovelace to ADA (1 ADA = 1,000,000 lovelace)
lovelaceToAda :: Number -> Number
lovelaceToAda n = n / 1_000_000.0

-- | Scroll the page to the top
scrollToTop :: Effect Unit
scrollToTop = DaisyUI.scrollToTop
