module Capabilities.InteractionMonad
  where

import Prelude

import Affjax as AX
import Affjax.RequestBody as AXRB
import Affjax.RequestHeader as AXRH
import Affjax.ResponseFormat as AXRF
import Affjax.Web as AXW
import Capabilities.MonadCIP30 (class MonadCIP30)
import Capabilities.MonadCIP30 as Cip30
import Cardano.Wallet.Cip30 (Api)
import Control.Monad.Reader (class MonadReader)
import Data.Argonaut.Aeson.Decode.Generic (genericDecodeAeson)
import Data.Argonaut.Aeson.Encode.Generic (genericEncodeAeson)
import Data.Argonaut.Aeson.Options as Argonaut
import Data.Argonaut.Decode (decodeJson, printJsonDecodeError)
import Data.Argonaut.Decode.Class (class DecodeJson, class DecodeJsonField)
import Data.Argonaut.Decode.Error (JsonDecodeError)
import Data.Argonaut.Encode (encodeJson)
import Data.Argonaut.Encode.Class (class EncodeJson)
import Data.Either (Either(..), either)
import Data.Generic.Rep (class Generic)
import Data.HTTP.Method (Method(..))
import Data.Lens (Iso')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype, unwrap)
import Data.String.Base64 as Base64
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Effect.Aff.Class (class MonadAff)
import Effect.Exception (throw)
import Halogen as H
import Prim (Array, String)


newtype ServerEnv = ServerEnv 
  { buildTxURL :: String
  , signAndSubmitTxURL :: String
  , basicUser :: String
  , basicPassword :: String
  }

instance encodeJsonServerEnv :: EncodeJson ServerEnv where
  encodeJson = genericEncodeAeson Argonaut.defaultOptions

instance decodeJsonServerEnv :: DecodeJson ServerEnv where
  decodeJson = genericDecodeAeson Argonaut.defaultOptions

derive instance genericServerEnv :: Generic ServerEnv _

derive instance newtypeServerEnv :: Newtype ServerEnv _

_ServerEnv :: Iso' ServerEnv { buildTxURL :: String, signAndSubmitTxURL :: String, basicUser :: String, basicPassword :: String }
_ServerEnv = _Newtype

defaultServerEnv :: ServerEnv
defaultServerEnv = ServerEnv 
  { buildTxURL: "http://localhost:8082/build-tx",
     signAndSubmitTxURL: "http://localhost:8082/sign-and-submit-tx", basicUser: "cardano", basicPassword: "lovelace" }
--------------------------------------------------------------------------------



newtype UserAddresses
  = UserAddresses
  { usedAddresses :: Array String
  , changeAddress :: String
  , reservedCollateral :: Maybe String
  , stakeAddress :: Maybe String
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
    , reservedCollateral :: Maybe String
    , stakeAddress :: Maybe String
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
      awasTxUnsigned :: String
    , awasTxWit :: String
    }

instance encodeJsonAddWitAndSubmitParams :: EncodeJson AddWitAndSubmitParams where
  encodeJson = genericEncodeAeson Argonaut.defaultOptions
instance decodeJsonAddWitAndSubmitParams :: DecodeJson AddWitAndSubmitParams where
  decodeJson = genericDecodeAeson Argonaut.defaultOptions
derive instance genericAddWitAndSubmitParams :: Generic AddWitAndSubmitParams _
derive instance newtypeAddWitAndSubmitParams :: Newtype AddWitAndSubmitParams _

--------------------------------------------------------------------------------
_AddWitAndSubmitParams :: Iso' AddWitAndSubmitParams { awasTxUnsigned :: String, awasTxWit :: String}
_AddWitAndSubmitParams = _Newtype

--------------------------------------------------------------------------------

getDecodedJson ∷ ∀ a. Either JsonDecodeError a → Effect a
getDecodedJson = either (throw <<< printJsonDecodeError) pure





class
  ( Monad m
  , MonadAff m
  , DecodeJson a
  , EncodeJson a
  , DecodeJsonField a
  ) <= InteractionMonad a m where
  buildTransaction :: ServerEnv -> Interaction a -> m (Either String String)
  signAndSubmitTransaction :: ServerEnv -> Api -> String -> m (Either String String)


buildTransactionDefault ::
  forall a m.
  MonadAff m =>
  EncodeJson a =>
  DecodeJson a =>
  DecodeJsonField a =>
  ServerEnv -> Interaction a -> m (Either String String)
buildTransactionDefault serverEnv interaction = do 
      let
          env = unwrap serverEnv
          req = 
                { url : env.buildTxURL
                , method : Left POST
                , responseFormat : AXRF.json  
                , headers :
                    [ AXRH.RequestHeader "Authorization" ("Basic " <> (Base64.encode (env.basicUser <> ":" <> env.basicPassword)))
                    ]
                , content : Just $ AXRB.Json $ encodeJson interaction
                , password : Just env.basicPassword
                , username : Just env.basicUser
                , timeout : Just $ Milliseconds 30000.0
                , withCredentials : true
                }
      result <- H.liftAff $ AXW.request req
      case result of 
        Right success -> do
            txCBOR <- H.liftEffect $ getDecodedJson $ decodeJson @String (_.body success)
            pure $ Right txCBOR
        Left e -> pure $  Left $ AX.printError e



signAndSubmitTransactionDefault::
  forall m.
  MonadAff m =>
  MonadCIP30 m =>
  ServerEnv ->  Api -> String -> m (Either String String)
signAndSubmitTransactionDefault serverEnv api unsignedTxCbor = do 
    signedTx <- Cip30.signTx api unsignedTxCbor true 
    let
        env = unwrap serverEnv
        req = 
              { url : env.signAndSubmitTxURL
              , method : Left POST
              , responseFormat : AXRF.json  
              , headers :
                  [ AXRH.RequestHeader "Authorization" ("Basic " <> (Base64.encode (env.basicUser <> ":" <> env.basicPassword)))
                  ]
              , content : Just $ AXRB.Json  $ encodeJson (AddWitAndSubmitParams { awasTxUnsigned: unsignedTxCbor, awasTxWit: signedTx })
              , password : Just env.basicPassword
              , username : Just env.basicUser
              , timeout : Just $ Milliseconds 30000.0
              , withCredentials : true
              }
    result <- H.liftAff $ AXW.request req
    case result of 
      Right success -> do
          txCBOR <- H.liftEffect $ getDecodedJson $ decodeJson @String (_.body success)
          pure $ Right txCBOR
      Left e -> pure $  Left $ AX.printError e


instance interactionMonadDefault ::
  ( MonadAff m
  , MonadReader ServerEnv m
  , EncodeJson a
  , DecodeJson a
  , DecodeJsonField a
  , MonadCIP30 m
  ) => InteractionMonad a m where
    buildTransaction = buildTransactionDefault
    signAndSubmitTransaction = signAndSubmitTransactionDefault