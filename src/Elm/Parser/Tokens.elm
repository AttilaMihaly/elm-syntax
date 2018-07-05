module Elm.Parser.Tokens
    exposing
        ( asToken
        , caseToken
        , characterLiteral
        , elseToken
        , exposingToken
        , functionName
        , functionOrTypeName
        , ifToken
        , importToken
        , infixOperatorToken
        , moduleToken
        , multiLineStringLiteral
        , ofToken
        , portToken
        , prefixOperatorToken
        , stringLiteral
        , thenToken
        , typeName
        )

import Char exposing (fromCode)
import Combine exposing ((*>), (<$), (<$>), (<*), (>>=), Parser, between, choice, count, fail, lookAhead, many, many1, or, regex, string, succeed)
import Combine.Char exposing (anyChar, char, oneOf)
import Dict exposing (Dict)
import Hex


reserved : Dict String Bool
reserved =
    [ "module"
    , "exposing"
    , "import"
    , "as"
    , "if"
    , "then"
    , "else"
    , "let"
    , "in"
    , "case"
    , "of"
    , "port"
    , "infixr"
    , "infixl"
    , "type"

    --, "alias" Apparently this is not a reserved keyword
    , "where"
    ]
        |> List.map (flip (,) True)
        |> Dict.fromList


portToken : Parser s String
portToken =
    string "port"


moduleToken : Parser s String
moduleToken =
    string "module"


exposingToken : Parser s String
exposingToken =
    string "exposing"


importToken : Parser s String
importToken =
    string "import"


asToken : Parser s String
asToken =
    string "as"


ifToken : Parser s String
ifToken =
    string "if"


thenToken : Parser s String
thenToken =
    string "then"


elseToken : Parser s String
elseToken =
    string "else"


caseToken : Parser s String
caseToken =
    string "case"


ofToken : Parser s String
ofToken =
    string "of"


functionOrTypeName : Parser s String
functionOrTypeName =
    or functionName typeName


notReserved : String -> Parser s String
notReserved match =
    if Dict.member match reserved then
        fail "functionName is reserved"
    else
        succeed match


escapedChar : Parser s Char
escapedChar =
    char '\\'
        *> choice
            [ '\'' <$ char '\''
            , '"' <$ char '"'
            , '\n' <$ char 'n'
            , '\t' <$ char 't'
            , '\\' <$ char '\\'
            , '\x07' <$ char 'a'
            , '\x08' <$ char 'b'
            , '\x0C' <$ char 'f'
            , '\x0D' <$ char 'r'
            , '\x0B' <$ char 'v'
            , (char 'x' *> regex "([0-9A-Fa-f]{2}){1,2}")
                >>= (\l ->
                        case Hex.fromString <| String.toLower l of
                            Ok x ->
                                succeed (fromCode x)

                            Err x ->
                                fail x
                    )
            ]


quotedSingleQuote : Parser s Char
quotedSingleQuote =
    char '\''
        *> escapedChar
        <* char '\''


characterLiteral : Parser s Char
characterLiteral =
    or quotedSingleQuote
        (char '\'' *> anyChar <* char '\'')


stringLiteral : Parser s String
stringLiteral =
    char '"'
        *> (String.concat
                <$> many
                        (choice
                            [ regex "[^\\\\\\\"]+"
                            , String.fromChar <$> escapedChar
                            ]
                        )
           )
        <* char '"'


multiLineStringLiteral : Parser s String
multiLineStringLiteral =
    between
        (string "\"\"\"")
        (string "\"\"\"")
        (String.concat
            <$> many
                    (or (regex "[^\\\\\\\"]+")
                        (lookAhead (count 3 anyChar)
                            >>= (\x ->
                                    if x == [ '"', '"', '"' ] then
                                        fail "end of input"
                                    else
                                        String.fromChar <$> or escapedChar anyChar
                                )
                        )
                    )
        )


functionNamePattern : String
functionNamePattern =
    "[a-z][a-zA-Z0-9_]*'?"


functionNamePatternInfix : String
functionNamePatternInfix =
    "`([A-Z][a-zA-Z0-9_]*\\.)*[a-z][a-zA-Z0-9_]*'?`"


functionName : Parser s String
functionName =
    or
        (regex functionNamePatternInfix)
        (regex functionNamePattern >>= notReserved)


typeName : Parser s String
typeName =
    regex "[A-Z][a-zA-Z0-9_]*"


excludedOperators : List String
excludedOperators =
    [ ":", "->", "--", "=" ]


allowedOperatorTokens : List Char
allowedOperatorTokens =
    [ '+', '-', ':', '/', '*', '>', '<', '=', '/', '&', '^', '%', '|', '!', '.', '#', '$', '≡', '~', '?', '@' ]


allowedPrefixOperatorTokens : List Char
allowedPrefixOperatorTokens =
    ',' :: allowedOperatorTokens


prefixOperatorToken : Parser s String
prefixOperatorToken =
    operatorTokenFromList allowedPrefixOperatorTokens


infixOperatorToken : Parser s String
infixOperatorToken =
    operatorTokenFromList allowedOperatorTokens


operatorTokenFromList : List Char -> Parser s String
operatorTokenFromList allowedChars =
    String.fromList
        <$> many1 (oneOf allowedChars)
        >>= (\m ->
                if List.member m excludedOperators then
                    fail "operator is not allowed"
                else
                    succeed m
            )
