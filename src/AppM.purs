module AppM
  ( AppM
  , getDecodedJson
  , runAppM
  ) where

import Prelude

import AppEnv (Env)
import Capabilities.MonadCIP30 (class MonadCIP30)
import Capabilities.MonadCardanoQuery (class MonadCardanoQuery, fetchPoolInfoDefault)
import Cardano.Wallet.Cip30 as Cip30
import Control.Monad.Error.Class (class MonadThrow)
import Control.Monad.Reader (class MonadReader, ReaderT, runReaderT)
import Control.Monad.Reader.Class (class MonadAsk)
import Data.Argonaut.Decode (JsonDecodeError, printJsonDecodeError)
import Data.Either (Either, either)
import Effect (Effect)
import Effect.Aff (Aff, Error)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (class MonadEffect)
import Effect.Exception (throw)
import Halogen as H
import Halogen.Store.Monad (class MonadStore, StoreT, runStoreT)
import Safe.Coerce (coerce)
import Store as Store

------
newtype AppM a
  = AppM (ReaderT Env (StoreT Store.Action Store.Store Aff) a)

runAppM ::
  forall q i o.
  Env ->
  Store.Store ->
  H.Component q i o AppM ->
  Aff (H.Component q i o Aff)
runAppM env initialStore rootComponent =
  runStoreT initialStore Store.reduce
    $ (H.hoist hoistToAff (coerce rootComponent))
  where
  hoistToAff :: forall a. ReaderT Env (StoreT Store.Action Store.Store Aff) a -> (StoreT Store.Action Store.Store Aff a)
  hoistToAff m = runReaderT m env

derive newtype instance functorAppM :: Functor AppM

derive newtype instance applyAppM :: Apply AppM

derive newtype instance applicativeAppM :: Applicative AppM

derive newtype instance bindAppM :: Bind AppM

derive newtype instance monadAppM :: Monad AppM

derive newtype instance monadEffectAppM :: MonadEffect AppM

derive newtype instance monadAffAppM :: MonadAff AppM

derive newtype instance monadStoreAppM :: MonadStore Store.Action Store.Store AppM

derive newtype instance monadErrorAppM :: MonadThrow Error AppM

derive newtype instance monadReaderAppM :: MonadReader Env AppM

derive newtype instance monadAskAppM :: MonadAsk Env AppM

getDecodedJson ∷ ∀ a. Either JsonDecodeError a → Effect a
getDecodedJson = either (throw <<< printJsonDecodeError) pure

-- MonadCIP30 instance required by external WalletConnect component
instance monadCip30AppM :: MonadCIP30 AppM where
  enable w exts = H.liftAff $ Cip30.enable w exts
  getExtensions = H.liftAff <<< Cip30.getExtensions
  getNetworkId = H.liftAff <<< Cip30.getNetworkId
  getBalance = H.liftAff <<< Cip30.getBalance
  getUsedAddresses api mp = H.liftAff $ Cip30.getUsedAddresses api mp
  getUtxos api ma mp = H.liftAff $ Cip30.getUtxos api ma mp
  getCollateral api amt = H.liftAff $ Cip30.getCollateral api amt
  getUnusedAddresses = H.liftAff <<< Cip30.getUnusedAddresses
  getChangeAddress = H.liftAff <<< Cip30.getChangeAddress
  getRewardAddresses = H.liftAff <<< Cip30.getRewardAddresses
  signTx api tx isPartial = H.liftAff $ Cip30.signTx api tx isPartial
  signData api addr payload = H.liftAff $ Cip30.signData api addr payload
  submitTx api tx = H.liftAff $ Cip30.submitTx api tx
  getName = H.liftEffect <<< Cip30.getName
  getIcon = H.liftEffect <<< Cip30.getIcon
  isWalletAvailable = H.liftEffect <<< Cip30.isWalletAvailable
  getAvailableWallets = H.liftEffect Cip30.getAvailableWallets
  isEnabled = H.liftAff <<< Cip30.isEnabled
  getApiVersion = H.liftEffect <<< Cip30.getApiVersion
  getSupportedExtensions = H.liftEffect <<< Cip30.getSupportedExtensions

-- MonadCardanoQuery instance
instance monadCardanoQueryAppM :: MonadCardanoQuery AppM where
  fetchPoolInfo = fetchPoolInfoDefault

