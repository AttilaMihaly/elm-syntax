module Elm.Parser.TypingsTests exposing (..)

import Elm.Parser.CombineTestUtil exposing (..)
import Elm.Parser.Typings as Parser
import Elm.Syntax.Range exposing (emptyRange)
import Elm.Syntax.TypeAnnotation exposing (..)
import Expect
import Test exposing (..)


all : Test
all =
    describe "TypeAlias"
        [ test "type alias" <|
            \() ->
                parseFullStringWithNullState "type alias Foo = {color: String }" Parser.typeAlias
                    |> Maybe.map noRangeTypeAlias
                    |> Expect.equal
                        (Just <|
                            { documentation = Nothing
                            , name = "Foo"
                            , generics = []
                            , typeAnnotation = Record [ ( "color", Typed [] "String" [] emptyRange ) ] emptyRange
                            , range = emptyRange
                            }
                        )
        , test "type alias with GenericType " <|
            \() ->
                parseFullStringWithNullState "type alias Foo a = {some : a }" Parser.typeAlias
                    |> Maybe.map noRangeTypeAlias
                    |> Expect.equal
                        (Just <|
                            { documentation = Nothing
                            , name = "Foo"
                            , generics = [ "a" ]
                            , typeAnnotation = Record [ ( "some", GenericType "a" emptyRange ) ] emptyRange
                            , range = emptyRange
                            }
                        )
        , test "type" <|
            \() ->
                parseFullStringWithNullState "type Color = Blue String | Red | Green" Parser.typeDeclaration
                    |> Maybe.map noRangeTypeDeclaration
                    |> Expect.equal
                        (Just
                            { name = "Color"
                            , generics = []
                            , constructors =
                                [ { name = "Blue"
                                  , arguments = [ Typed [] "String" [] emptyRange ]
                                  , range = emptyRange
                                  }
                                , { name = "Red"
                                  , arguments = []
                                  , range = emptyRange
                                  }
                                , { name = "Green"
                                  , arguments = []
                                  , range = emptyRange
                                  }
                                ]
                            }
                        )
        , test "type with GenericType " <|
            \() ->
                parseFullStringWithNullState "type Maybe a = Just a | Nothing" Parser.typeDeclaration
                    |> Maybe.map noRangeTypeDeclaration
                    |> Expect.equal
                        (Just
                            { name = "Maybe"
                            , generics = [ "a" ]
                            , constructors =
                                [ { name = "Just"
                                  , arguments = [ GenericType "a" emptyRange ]
                                  , range = emptyRange
                                  }
                                , { name = "Nothing", arguments = [], range = emptyRange }
                                ]
                            }
                        )
        , test "type with value on next line " <|
            \() ->
                parseFullStringWithNullState "type Maybe a = Just a |\nNothing" Parser.typeDeclaration
                    |> Expect.equal Nothing
        ]
