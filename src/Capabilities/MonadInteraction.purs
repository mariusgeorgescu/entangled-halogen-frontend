module Capabilities.MonadInteraction
  ( AddWitAndSubmitParams(..)
  , Interaction(..)
  , UserAddresses(..)
  , _AddWitAndSubmitParams
  , _Interaction
  , _UserAddresses
  , buildTransactionDefault
  , buildTransactionFromInteraction
  , class MonadInteraction
  , buildTransaction
  , submitTransaction
  , signTransaction
  , getDecodedJson
  , signTransactionDefault
  , submitTransactionDefault
  )
  where

import Prelude

import Affjax (Error(..))
import Affjax as AX
import Affjax.RequestBody as AXRB
import Affjax.ResponseFormat as AXRF
import Affjax.Web as AXW
import Capabilities.MonadCIP30 (class MonadCIP30)
import Capabilities.MonadCIP30 as Cip30
import Cardano.Wallet.Cip30 (Api)
import Data.Argonaut.Aeson.Decode.Generic (genericDecodeAeson)
import Data.Argonaut.Aeson.Encode.Generic (genericEncodeAeson)
import Data.Argonaut.Aeson.Options as Argonaut
import Data.Argonaut.Decode (decodeJson, printJsonDecodeError)
import Data.Argonaut.Decode.Class (class DecodeJson, class DecodeJsonField)
import Data.Argonaut.Decode.Error (JsonDecodeError)
import Data.Argonaut.Encode (encodeJson, toJsonString)
import Data.Argonaut.Encode.Class (class EncodeJson)
import Data.Either (Either(..), either)
import Data.Generic.Rep (class Generic)
import Data.HTTP.Method (Method(..))
import Data.Lens (Iso')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Effect.Aff.Class (class MonadAff)
import Effect.Exception (throw)
import Foreign (ForeignError(..), unsafeFromForeign)
import Halogen as H
import Prim (Array, Int, String)
import Test.Unit.Console (consoleLog)



newtype UserAddresses
  = UserAddresses
  { usedAddresses :: Array String
  , changeAddress :: String
  , stakeAddresses :: Array String
  }

instance encodeJsonUserAddresses :: EncodeJson UserAddresses where
  encodeJson = genericEncodeAeson Argonaut.defaultOptions

instance decodeJsonUserAddresses :: DecodeJson UserAddresses where
  decodeJson = genericDecodeAeson Argonaut.defaultOptions

derive instance genericUserAddresses :: Generic UserAddresses _

derive instance newtypeUserAddresses :: Newtype UserAddresses _

_UserAddresses ::
  Iso' UserAddresses
    { usedAddresses :: Array String
    , changeAddress :: String
    , stakeAddresses :: Array String
    }
_UserAddresses = _Newtype

--------------------------------------------------------------------------------
newtype Interaction a
  = Interaction
  { action :: a
  , userAddresses :: UserAddresses
  , recipient :: Maybe String
  }

instance encodeJsonInteraction :: EncodeJson a => EncodeJson (Interaction a) where
  encodeJson = genericEncodeAeson Argonaut.defaultOptions

instance decodeJsonInteraction :: (DecodeJson a, DecodeJsonField a) => DecodeJson (Interaction a) where
  decodeJson = genericDecodeAeson Argonaut.defaultOptions

derive instance genericInteraction :: Generic (Interaction a) _

derive instance newtypeInteraction :: Newtype (Interaction a) _

_Interaction :: forall a. Iso' (Interaction a) { action :: a, userAddresses :: UserAddresses, recipient :: Maybe String }
_Interaction = _Newtype

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
newtype AddWitAndSubmitParams =
    AddWitAndSubmitParams {
      tx_unsigned :: String
    , tx_wit :: String
    }

instance encodeJsonAddWitAndSubmitParams :: EncodeJson AddWitAndSubmitParams where
  encodeJson = genericEncodeAeson Argonaut.defaultOptions
instance decodeJsonAddWitAndSubmitParams :: DecodeJson AddWitAndSubmitParams where
  decodeJson = genericDecodeAeson Argonaut.defaultOptions
derive instance genericAddWitAndSubmitParams :: Generic AddWitAndSubmitParams _
derive instance newtypeAddWitAndSubmitParams :: Newtype AddWitAndSubmitParams _

--------------------------------------------------------------------------------
_AddWitAndSubmitParams :: Iso' AddWitAndSubmitParams { tx_unsigned :: String, tx_wit :: String}
_AddWitAndSubmitParams = _Newtype

--------------------------------------------------------------------------------

getDecodedJson ∷ ∀ a. Either JsonDecodeError a → Effect a
getDecodedJson = either (throw <<< printJsonDecodeError) pure


type HasEnv r = { buildTxURL :: String, submitTxURL :: String, allowedNetworkId :: Int | r}

class
  ( Monad m
  , MonadAff m
  , DecodeJson a
  , EncodeJson a
  , MonadCIP30 m
  , DecodeJsonField a

  ) <= MonadInteraction   a m   where
  buildTransaction :: forall r. (HasEnv r) -> Api -> a -> m (Either String String)
  submitTransaction :: forall r. (HasEnv r) -> String -> String -> m (Either String String)
  signTransaction ::  Api -> String -> m (Either String String)


signTransactionDefault ::
  forall m.
  MonadAff m =>
  MonadCIP30 m =>
  Api -> String -> m (Either String String)
signTransactionDefault api unsignedTxCbor = do
  signedTx <- Cip30.signTx api unsignedTxCbor true
  pure $ Right signedTx


buildTransactionDefault ::
  forall a m r.
  MonadAff m =>
  EncodeJson a =>
  DecodeJson a =>
  DecodeJsonField a =>
  MonadCIP30 m =>
  (HasEnv r) ->  Api ->  a -> m (Either String String)
buildTransactionDefault serverEnv api a = do 
    usedAddresses <-  Cip30.getUsedAddresses api Nothing
    changeAddress <- Cip30.getChangeAddress api
    stakeAddresses <- Cip30.getRewardAddresses api
    let interaction = 
            Interaction
                { action: a
                , recipient: Nothing
                , userAddresses:
                    UserAddresses
                      { usedAddresses: usedAddresses
                      , changeAddress: changeAddress
                      , stakeAddresses: stakeAddresses
                      }
                }
    H.liftEffect $ consoleLog $ show (toJsonString interaction)
    buildTransactionFromInteraction serverEnv interaction

buildTransactionFromInteraction ::
  forall a m r.
  MonadAff m =>
  EncodeJson a =>
  DecodeJson a =>
  DecodeJsonField a =>
  (HasEnv r) -> Interaction a -> m (Either String String)
buildTransactionFromInteraction env interaction = do
  let 

      req =
            { url : env.buildTxURL
            , method : Left POST
            , responseFormat : AXRF.json
            , headers : []
            -- BFF handles authentication, so we don't need Authorization header here
            , content : Just $ AXRB.Json $ encodeJson interaction
            , password : Nothing
            , username : Nothing
            , timeout : Just $ Milliseconds 10_000_000.0
            , withCredentials : true
            }
  result <- H.liftAff $ AXW.request req
  case result of
    Right success -> do
        txCBOR <- H.liftEffect $ getDecodedJson $ decodeJson @String (_.body success)
        pure $ Right txCBOR
    Left (ResponseBodyError (ForeignError _msg) resp) -> do 
        pure $ Left $ (unsafeFromForeign resp.body)
    Left e -> pure $ Left $ AX.printError e

submitTransactionDefault::
  forall m r.
  MonadAff m =>
  MonadCIP30 m =>
  (HasEnv r) ->   String -> String -> m (Either String String)
submitTransactionDefault env  unsignedTxCbor signedTx = do 
   
    let

        req = 
              { url : env.submitTxURL
              , method : Left POST
              , responseFormat : AXRF.json  
              , headers : []
              -- BFF handles authentication, so we don't need Authorization header here
              , content : Just $ AXRB.Json  $ encodeJson (AddWitAndSubmitParams { tx_unsigned: unsignedTxCbor, tx_wit: signedTx })
              , password : Nothing
              , username : Nothing
              , timeout : Just $ Milliseconds 10_000_000.0
              , withCredentials : true
              }
    result <- H.liftAff $ AXW.request req
    case result of 
      Right success -> do
          txCBOR <- H.liftEffect $ getDecodedJson $ decodeJson @String (_.body success)
          pure $ Right txCBOR
      Left (ResponseBodyError (ForeignError _msg) resp) -> do 
        pure $ Left $ (unsafeFromForeign resp.body)
      Left e -> pure $  Left $ AX.printError e


instance interactionMonadDefault ::
  ( MonadAff m
  , EncodeJson a
  , DecodeJson a
  , DecodeJsonField a
  , MonadCIP30 m
  ) => MonadInteraction a m where
    buildTransaction env api a = buildTransactionDefault env api a
    submitTransaction env unsignedTxCbor signedTx = submitTransactionDefault env unsignedTxCbor signedTx
    signTransaction = signTransactionDefault