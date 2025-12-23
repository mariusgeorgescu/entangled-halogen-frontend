module AppM
  ( AppM
  , getDecodedJson
  , runAppM
  ) where

import Prelude

import AppEnv (Env)
import Cardano.Capabilities (class MonadCardanoQuery, class MonadInteraction, class MonadCIP30)
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

-- Empty marker instances for cardano-capabilities library
-- All functionality comes from standalone functions
-- MonadCIP30 is automatically provided by the library for MonadAff instances
instance MonadCIP30 AppM
instance MonadInteraction AppM
instance MonadCardanoQuery AppM
