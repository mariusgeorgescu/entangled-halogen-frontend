module AppTypes
  ( DelegationAction(..)
  ) where

import Prelude

import Data.Argonaut.Aeson.Decode.Generic (genericDecodeAeson)
import Data.Argonaut.Aeson.Encode.Generic (genericEncodeAeson)
import Data.Argonaut.Aeson.Options as Argonaut
import Data.Argonaut.Decode.Class (class DecodeJson)
import Data.Argonaut.Encode.Class (class EncodeJson)
import Data.Eq (class Eq)
import Data.Generic.Rep (class Generic)

data DelegationAction
  = DRepDelegation { dRepHash :: String }
  | PoolDelegation { poolId :: String }
  | PoolAndDRepDelegation { poolId :: String, dRepHash :: String }

-- Using defaultOptions which matches Haskell Aeson default behavior:
-- - TaggedObject encoding with "tag" as tagFieldName  
-- - Record fields are flattened into the same object as the tag (for record constructors)
-- - This produces: {"tag": "DRepDelegation", "dRepHash": "..."}
instance encodeJsonDelegationAction :: EncodeJson DelegationAction where
  encodeJson = genericEncodeAeson Argonaut.defaultOptions

instance decodeJsonDelegationAction :: DecodeJson DelegationAction where
  decodeJson = genericDecodeAeson Argonaut.defaultOptions

derive instance genericServerEnv :: Generic DelegationAction _

derive instance eqUserAction :: Eq DelegationAction
