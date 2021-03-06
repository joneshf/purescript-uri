module Data.URI.Host where

import Prelude

import Control.Alt ((<|>))
import Data.Int as Int
import Data.Maybe (Maybe(..))
import Data.URI (Host(..))
import Data.URI.Common (decodePCT, joinWith, parsePCTEncoded, parseSubDelims, parseUnreserved, rxPat)
import Global (encodeURI)
import Text.Parsing.StringParser (Parser, try, fail)
import Text.Parsing.StringParser.Combinators ((<?>), many1)
import Text.Parsing.StringParser.String (string, char)

parser ∷ Parser Host
parser = ipv6AddressParser <|> ipv4AddressParser <|> try regNameParser

-- TODO: this is much too forgiving right now
ipv6AddressParser ∷ Parser Host
ipv6AddressParser = IPv6Address <$> (string "[" *> rxPat "[a-f0-9\\.:]+" <* string "]") <?> "IPv6 address"

ipv4AddressParser ∷ Parser Host
ipv4AddressParser = IPv4Address <$> addr <?> "IPv4 address"
  where
  addr ∷ Parser String
  addr = do
    o1 <- octet
    _ <- char '.'
    o2 <- octet
    _ <- char '.'
    o3 <- octet
    _ <- char '.'
    o4 <- octet
    pure $ show o1 <> "." <> show o2 <> "." <> show o3 <> "." <> show o4
  octet ∷ Parser Int
  octet = do
    s <- rxPat "0|([1-9][0-9]{0,2})"
    case Int.fromString s of
      Just n | n >= 0 && n <= 255 -> pure n
      _ -> fail "Invalid IPv4 address octet"

regNameParser ∷ Parser Host
regNameParser = NameAddress <<< joinWith "" <$> many1 p
  where
  p = parseUnreserved <|> parsePCTEncoded decodePCT <|> parseSubDelims

print ∷ Host → String
print (IPv6Address i) = "[" <> i <> "]"
print (IPv4Address i) = i
print (NameAddress i) = encodeURI i
