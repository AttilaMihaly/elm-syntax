module Elm.Parser.Typings exposing (typeDeclaration, typeAlias)

import Combine exposing (Parser, string, sepBy, many, succeed, (<*>), (*>))
import Elm.Parser.Tokens exposing (functionName, typeName)
import Elm.Parser.TypeAnnotation exposing (typeAnnotation)
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Parser.Util exposing (moreThanIndentWhitespace, trimmed)
import Elm.Parser.State exposing (State)
import Elm.Parser.Ranges exposing (withRange)


typeDeclaration : Parser State Type
typeDeclaration =
    succeed Type
        <*> (typePrefix *> typeName)
        <*> genericList
        <*> (trimmed (string "=") *> valueConstructors)


valueConstructors : Parser State (List ValueConstructor)
valueConstructors =
    sepBy (string "|") (trimmed valueConstructor)


valueConstructor : Parser State ValueConstructor
valueConstructor =
    withRange
        (succeed ValueConstructor
            <*> typeName
            <*> many (moreThanIndentWhitespace *> typeAnnotation)
        )


typeAlias : Parser State TypeAlias
typeAlias =
    withRange <|
        succeed (TypeAlias Nothing)
            <*> (typeAliasPrefix *> typeName)
            <*> genericList
            <*> (trimmed (string "=") *> typeAnnotation)


genericList : Parser State (List String)
genericList =
    many (moreThanIndentWhitespace *> functionName)


typePrefix : Parser State ()
typePrefix =
    string "type" *> moreThanIndentWhitespace


typeAliasPrefix : Parser State ()
typeAliasPrefix =
    typePrefix *> string "alias" *> moreThanIndentWhitespace
