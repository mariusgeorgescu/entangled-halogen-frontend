module AppEnv where

import Capabilities.MonadInteraction (ServerEnv, defaultServerEnv)

-----------------
-- Env Type
-----------------
-- | The application environment
type Env
  = ServerEnv

defaultEnv :: Env
defaultEnv = defaultServerEnv
