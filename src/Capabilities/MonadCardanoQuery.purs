module Capabilities.MonadCardanoQuery
  ( class MonadCardanoQuery
  , fetchPoolInfo
  , fetchPoolInfoDefault
  , PoolInfo(..)
  ) where

import Prelude

import Affjax as AX
import Affjax.ResponseFormat as AXRF
import Affjax.Web as AXW
import Control.Monad.Reader.Class (class MonadAsk, ask)
import Data.Argonaut.Aeson.Decode.Generic (genericDecodeAeson)
import Data.Argonaut.Aeson.Options as Argonaut
import Data.Argonaut.Decode (decodeJson)
import Data.Argonaut.Decode.Class (class DecodeJson)
import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.HTTP.Method (Method(..))
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Number as Number
import Data.Time.Duration (Milliseconds(..))
import Effect.Aff.Class (class MonadAff)
import Foreign (ForeignError(..), unsafeFromForeign)
import Halogen as H

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

newtype PoolInfoMaestroResponse
  = PoolInfoMaestroResponse
    { data :: Maybe PoolData
    }

derive instance genericPoolInfoMaestroResponse :: Generic PoolInfoMaestroResponse _
derive instance newtypePoolInfoMaestroResponse :: Newtype PoolInfoMaestroResponse _

instance decodeJsonPoolInfoMaestroResponse :: DecodeJson PoolInfoMaestroResponse where
  decodeJson = genericDecodeAeson Argonaut.defaultOptions

-- Custom decoder that extracts nested data
instance decodeJsonPoolInfo :: DecodeJson PoolInfo where
  decodeJson json = 
    case genericDecodeAeson Argonaut.defaultOptions json :: Either _ PoolInfoMaestroResponse of
      Right (PoolInfoMaestroResponse poolResponse) -> 
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

type HasPoolInfoEnv r = { poolInfoURL :: String | r }

class
  ( Monad m
  , MonadAff m
  ) <= MonadCardanoQuery m where
  fetchPoolInfo :: forall r. MonadAsk { poolInfoURL :: String | r } m => String -> m (Either String PoolInfo)

fetchPoolInfoDefault ::
  forall m r.
  MonadAff m =>
  MonadAsk { poolInfoURL :: String | r } m =>
  String -> m (Either String PoolInfo)
fetchPoolInfoDefault poolId = do
  env <- ask
  let url = env.poolInfoURL <> "/" <> poolId
  let req = 
        { url: url
        , method: Left GET
        , responseFormat: AXRF.json
        , headers: []
        , content: Nothing
        , password: Nothing
        , username: Nothing
        , timeout: Just $ Milliseconds 10_000_000.0
        , withCredentials: true
        }
  result <- H.liftAff $ AXW.request req
  case result of
    Right success -> do
      case decodeJson success.body of
        Right poolInfo -> pure $ Right poolInfo
        Left decodeErr -> pure $ Left $ "Failed to decode pool info: " <> show decodeErr
    Left (AX.ResponseBodyError (ForeignError _msg) resp) -> do
      pure $ Left $ unsafeFromForeign resp.body
    Left e -> do
      pure $ Left $ AX.printError e

-- Instance for HalogenM that lifts from the underlying monad
instance monadCardanoQueryHalogenM ::
  ( MonadCardanoQuery m
  , MonadAsk { poolInfoURL :: String | r } m
  ) =>
  MonadCardanoQuery (H.HalogenM state action slots output m) where
  fetchPoolInfo poolId = H.lift $ fetchPoolInfo poolId
