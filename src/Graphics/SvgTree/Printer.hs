module Graphics.SvgTree.Printer
  ( ppTree
  , ppDocument
  ) where

import           Control.Lens
import           Data.Char
import           Data.List
import           Graphics.SvgTree.Types     (DrawAttributes, Tree (..),
                                             groupChildren,
                                             preRendered, Document(..))
import           Graphics.SvgTree.XmlParser
import           Text.XML.Light

ppDocument :: Document -> String
ppDocument doc =
  ppElementS_ (_elements doc) (xmlOfDocument doc) ""

ppTree :: Tree -> String
ppTree t = ppTreeS t ""

ppTreeS :: Tree -> ShowS
ppTreeS tree =
  case tree ^. preRendered of
    Nothing ->
      case xmlOfTree tree of
        Just x  -> ppElementS_ (treeChildren tree) x
        Nothing -> id
    Just s -> showString s

treeChildren :: Tree -> [Tree]
treeChildren (GroupTree g)      = g^.groupChildren
treeChildren (SymbolTree g)     = g^.groupChildren
treeChildren (DefinitionTree g) = g^.groupChildren
treeChildren _                  = []

ppElementS_         :: [Tree] -> Element -> ShowS
ppElementS_ children e xs = tagStart name (elAttribs e) $
  case children of
    [] | "?" `isPrefixOf` qName name -> showString " ?>" xs
       | True  -> showString " />" xs
    _ -> showChar '>' (foldr ppTreeS (tagEnd name xs) children)
  where name = elName e

--------------------------------------------------------------------------------
tagStart           :: QName -> [Attr] -> ShowS
tagStart qn as rs   = '<':showQName qn ++ as_str ++ rs
 where as_str       = if null as then "" else ' ' : unwords (map showAttr as)
       showAttr           :: Attr -> String
       showAttr (Attr qn v) = showQName qn ++ '=' : '"' : v ++ "\""