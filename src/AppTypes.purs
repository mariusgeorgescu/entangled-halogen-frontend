module AppTypes
  ( DelegationAction(..)
  , PoolInfo(..)
  ) where

import Prelude

import Data.Argonaut.Aeson.Decode.Generic (genericDecodeAeson)
import Data.Argonaut.Aeson.Encode.Generic (genericEncodeAeson)
import Data.Argonaut.Aeson.Options as Argonaut
import Data.Argonaut.Decode.Class (class DecodeJson)
import Data.Argonaut.Encode.Class (class EncodeJson)
import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Number as Number

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

-- Pool Info type for Gomaestro API response
-- This is the extracted/processed version we use in the UI
newtype PoolInfo
  = PoolInfo
    { margin :: Maybe Number
    , fixed_cost :: Maybe Number
    , pledge :: Maybe Number
    , live_stake :: Maybe Number
    , active_stake :: Maybe Number
    , delegators :: Maybe Int
    , blocks :: Maybe Int
    , saturation :: Maybe Number
    , pool_id :: Maybe String
    , ticker :: Maybe String
    , name :: Maybe String
    }

derive instance genericPoolInfo :: Generic PoolInfo _
derive instance newtypePoolInfo :: Newtype PoolInfo _

-- Raw API response types
newtype PoolMetaJson
  = PoolMetaJson
    { name :: Maybe String
    , ticker :: Maybe String
    , homepage :: Maybe String
    , description :: Maybe String
    }

derive instance genericPoolMetaJson :: Generic PoolMetaJson _
derive instance newtypePoolMetaJson :: Newtype PoolMetaJson _

instance decodeJsonPoolMetaJson :: DecodeJson PoolMetaJson where
  decodeJson = genericDecodeAeson Argonaut.defaultOptions

newtype PoolData
  = PoolData
    { pool_id_bech32 :: Maybe String
    , margin :: Maybe Number
    , fixed_cost :: Maybe Number
    , pledge :: Maybe Number
    , live_stake :: Maybe Number
    , active_stake :: Maybe Number
    , block_count :: Maybe Int
    , live_delegators :: Maybe Int
    , live_saturation :: Maybe String
    , meta_json :: Maybe PoolMetaJson
    }

derive instance genericPoolData :: Generic PoolData _
derive instance newtypePoolData :: Newtype PoolData _

instance decodeJsonPoolData :: DecodeJson PoolData where
  decodeJson = genericDecodeAeson Argonaut.defaultOptions

newtype PoolInfoResponse
  = PoolInfoResponse
    { data :: Maybe PoolData
    }

derive instance genericPoolInfoResponse :: Generic PoolInfoResponse _
derive instance newtypePoolInfoResponse :: Newtype PoolInfoResponse _

instance decodeJsonPoolInfoResponse :: DecodeJson PoolInfoResponse where
  decodeJson = genericDecodeAeson Argonaut.defaultOptions

-- Custom decoder that extracts nested data
instance decodeJsonPoolInfo :: DecodeJson PoolInfo where
  decodeJson json = 
    case genericDecodeAeson Argonaut.defaultOptions json :: Either _ PoolInfoResponse of
      Right (PoolInfoResponse poolResponse) -> 
        case poolResponse.data of
          Just (PoolData poolData) -> 
            let
              meta = poolData.meta_json
              name = case meta of
                Just (PoolMetaJson m) -> m.name
                Nothing -> Nothing
              ticker = case meta of
                Just (PoolMetaJson m) -> m.ticker
                Nothing -> Nothing
              -- Parse live_saturation from String to Number
              saturation = case poolData.live_saturation of
                Just s -> case Number.fromString s of
                  Just n -> Just n
                  Nothing -> Nothing
                Nothing -> Nothing
            in
              Right $ PoolInfo
                { margin: poolData.margin
                , fixed_cost: poolData.fixed_cost
                , pledge: poolData.pledge
                , live_stake: poolData.live_stake
                , active_stake: poolData.active_stake
                , delegators: poolData.live_delegators
                , blocks: poolData.block_count
                , saturation: saturation
                , pool_id: poolData.pool_id_bech32
                , ticker: ticker
                , name: name
                }
          Nothing -> 
            Right $ PoolInfo
              { margin: Nothing
              , fixed_cost: Nothing
              , pledge: Nothing
              , live_stake: Nothing
              , active_stake: Nothing
              , delegators: Nothing
              , blocks: Nothing
              , saturation: Nothing
              , pool_id: Nothing
              , ticker: Nothing
              , name: Nothing
              }
      Left err -> Left err
