{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE OverloadedStrings #-}

module Network.Mattermost.Types where

import qualified Data.Aeson as A
import           Data.Aeson ( (.:) )
import qualified Data.HashMap.Strict as HM
import           Data.Ratio ( (%) )
import qualified Data.Text as T
import           Data.Time.Clock ( UTCTime )
import           Data.Time.Clock.POSIX ( posixSecondsToUTCTime )
import           Network.Connection (ConnectionContext)
import           Network.HTTP.Headers (Header, HeaderName(..), mkHeader)

type Hostname = String
type Port     = Int

-- For now we don't support or expose the ability to reuse connections,
-- but we have this field in case we want to support that in the future.
-- Doing so will require some modifications to withConnection (and uses).
-- Note: don't export this until we support connection reuse.
data AutoClose = No | Yes
  deriving (Read, Show, Eq, Ord)

-- | We return a list of headers so that we can treat
-- the headers like a monoid.
autoCloseToHeader :: AutoClose -> [Header]
autoCloseToHeader No  = []
autoCloseToHeader Yes = [mkHeader HdrConnection "Close"]


data ConnectionData
  = ConnectionData
  { cdHostname      :: Hostname
  , cdPort          :: Port
  , cdAutoClose     :: AutoClose
  , cdConnectionCtx :: ConnectionContext
  , cdToken         :: Maybe Token
  }

mkConnectionData :: Hostname -> Port -> ConnectionContext -> ConnectionData
mkConnectionData host port ctx = ConnectionData
  { cdHostname      = host
  , cdPort          = port
  , cdConnectionCtx = ctx
  , cdAutoClose     = Yes
  , cdToken         = Nothing
  }

data Token = Token String
  deriving (Read, Show, Eq, Ord)

getTokenString :: Token -> String
getTokenString (Token s) = s

--

data Login
  = Login
  { username :: T.Text
  , teamname :: T.Text
  , password :: T.Text
  }

instance A.ToJSON Login where
  toJSON l = A.object ["name"     A..= teamname l
                      ,"login_id" A..= username l
                      ,"password" A..= password l
                      ]


-- | XXX: No idea what this is
data Type = Type T.Text
  deriving (Read, Show, Ord, Eq)

instance A.FromJSON Type where
  parseJSON = A.withText "Type" (pure . Type)

--

newtype Id = Id { unId :: T.Text }
  deriving (Read, Show, Eq, Ord)

instance A.FromJSON Id where
  parseJSON = A.withText "Id" $ \s ->
    pure (Id s)

--

class HasId x where
  getId :: x -> String

instance HasId Team where
  getId = T.unpack . unId . teamId

data Team
  = Team
  { teamId              :: Id
  , teamCreateAt        :: UTCTime
  , teamUpdateAt        :: UTCTime
  , teamDeleteAt        :: UTCTime
  , teamDisplayName     :: String
  , teamName            :: String
  , teamEmail           :: String
  , teamType            :: Type
  , teamCompanyName     :: String
  , teamAllowedDomains  :: String
  , teamInviteId        :: Id
  , teamAllowOpenInvite :: Bool
  }
  deriving (Read, Show, Eq, Ord)

instance A.FromJSON Team where
  parseJSON = A.withObject "Team" $ \v -> do
    teamId              <- v .: "id"
    teamCreateAt        <- millisecondsToUTCTime <$> v .: "create_at"
    teamUpdateAt        <- millisecondsToUTCTime <$> v .: "update_at"
    teamDeleteAt        <- millisecondsToUTCTime <$> v .: "delete_at"
    teamDisplayName     <- v .: "display_name"
    teamName            <- v .: "name"
    teamEmail           <- v .: "email"
    teamType            <- v .: "type"
    teamCompanyName     <- v .: "company_name"
    teamAllowedDomains  <- v .: "allowed_domains"
    teamInviteId        <- v .: "invite_id"
    teamAllowOpenInvite <- v .: "allow_open_invite"
    return Team { .. }

data Channel
  = Channel
  { channelId            :: Id
  , channelCreateAt      :: UTCTime
  , channelUpdateAt      :: UTCTime
  , channelDeleteAt      :: UTCTime
  , channelTeamId        :: Id
  , channelType          :: Type
  , channelDisplayName   :: String
  , channelName          :: String
  , channelHeader        :: String
  , channelPurpose       :: String
  , channelLastPostAt    :: UTCTime
  , channelTotalMsgCount :: Int
  , channelExtraUpdateAt :: UTCTime
  , channelCreatorId     :: Id
  } deriving (Read, Show, Eq, Ord)

instance HasId Channel where
  getId = T.unpack . unId . channelId

instance A.FromJSON Channel where
  parseJSON = A.withObject "Channel" $ \v -> do
    channelId              <- v .: "id"
    channelCreateAt        <- millisecondsToUTCTime <$> v .: "create_at"
    channelUpdateAt        <- millisecondsToUTCTime <$> v .: "update_at"
    channelDeleteAt        <- millisecondsToUTCTime <$> v .: "delete_at"
    channelTeamId          <- v .: "team_id"
    channelType            <- v .: "type"
    channelDisplayName     <- v .: "display_name"
    channelName            <- v .: "name"
    channelHeader          <- v .: "header"
    channelPurpose         <- v .: "purpose"
    channelLastPostAt      <- millisecondsToUTCTime <$> v .: "last_post_at"
    channelTotalMsgCount   <- v .: "total_msg_count"
    channelExtraUpdateAt   <- millisecondsToUTCTime <$> v .: "extra_update_at"
    channelCreatorId       <- v .: "creator_id"
    return Channel { .. }

newtype ChannelList = CL [Channel]
  deriving (Read, Show, Eq, Ord)

instance A.FromJSON ChannelList where
  parseJSON = A.withObject "ChannelList" $ \o -> do
    chans <- o .: "channels"
    cl    <- mapM A.parseJSON chans
    return (CL cl)

--

millisecondsToUTCTime :: Integer -> UTCTime
millisecondsToUTCTime ms = posixSecondsToUTCTime (fromRational (ms%1000))

--

-- TODO: It's probably better to return the actual HashMap instead
-- of converting to a list. Let the user of the API decide what
-- they want.
newtype TeamList = TL [Team]
  deriving (Read, Show, Eq, Ord)

instance A.FromJSON TeamList where
  parseJSON = A.withObject "TeamList" $ \hm -> do
    let tl = map snd (HM.toList hm)
    tl' <- mapM A.parseJSON tl
    return (TL tl')
