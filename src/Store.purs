module Store where

import Prelude
import Cardano.Wallet.Cip30 (Api)
import Data.Array (cons, filter)
import Data.Maybe (Maybe(..))

type Store
  = { walletApi :: Maybe Api
    , walletName :: Maybe String
    , waitingforConfirmation :: Array String
    }

initialStore :: Store
initialStore = { walletApi: Nothing, walletName: Nothing, waitingforConfirmation: [] }

data Action
  = Connect Api String
  | Disconnect
  | AddToWaitingList String
  | RemoveFromWaitingList String

reduce :: Store -> Action -> Store
reduce store = case _ of
  Connect api name -> store { walletApi = Just api, walletName = Just name }
  Disconnect -> store { walletApi = Nothing, walletName = Nothing }
  AddToWaitingList raffleizeId -> store { waitingforConfirmation = raffleizeId `cons` store.waitingforConfirmation }
  RemoveFromWaitingList raffleizeId -> store { waitingforConfirmation = filter (not <<< (==) raffleizeId) store.waitingforConfirmation }
