module Main exposing (main)

import Browser exposing (element)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes
import Modal
import Platform


main : Platform.Program {} Model Msg
main =
    element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


init : {} -> ( Model, Cmd Msg )
init flags =
    ( Dict.fromList
        [ ( 0, Modal.init )
        , ( 1, Modal.init )
        , ( 2, Modal.init )
        ]
    , Cmd.none
    )


type alias Model =
    Dict Int Modal.Model


type Msg
    = ModalMsg Int Modal.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ModalMsg modalId modalMsg ->
            case Dict.get modalId model of
                Just modal ->
                    let
                        ( newModalState, modalCmd ) =
                            Modal.update modalMsg modal
                    in
                    ( Dict.insert modalId newModalState model
                    , Cmd.map (ModalMsg modalId) modalCmd
                    )

                Nothing ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Dict.toList model
        |> List.map (\( id, modal ) -> Sub.map (ModalMsg id) (Modal.subscriptions modal))
        |> Sub.batch


view : Model -> Html Msg
view model =
    div
        []
        [ h1 [] [ text "Modal examples" ]
        , case Dict.get 0 model of
            Just modal ->
                section []
                    [ h2 [] [ text "Single focusable element" ]
                    , Html.map (ModalMsg 0)
                        (Modal.view
                            { ifClosed = button [ Modal.openOnClick ] [ text "Launch Modal" ]
                            , ifOpen =
                                div []
                                    [ text "Modal content"
                                    , button
                                        (Modal.closeOnClick
                                            :: Modal.singleFocusableElement
                                        )
                                        [ text "Close Modal" ]
                                    ]
                            }
                            modal
                        )
                    ]

            Nothing ->
                text ""
        , case Dict.get 1 model of
            Just modal ->
                section []
                    [ h2 [] [ text "Two focusable elements" ]
                    , Html.map (ModalMsg 1)
                        (Modal.view
                            { ifClosed = button [ Modal.openOnClick ] [ text "Launch Modal" ]
                            , ifOpen =
                                div []
                                    [ text "Modal content"
                                    , button
                                        (Modal.closeOnClick
                                            :: Modal.firstFocusableElement
                                        )
                                        [ text "Close Modal" ]
                                    , a
                                        (Html.Attributes.href "www.noredink.com"
                                            :: Modal.lastFocusableElement
                                        )
                                        [ text "Go to noredink.come" ]
                                    ]
                            }
                            modal
                        )
                    ]

            Nothing ->
                text ""
        , case Dict.get 2 model of
            Just modal ->
                section []
                    [ h2 [] [ text "Three focusable elements" ]
                    , Html.map (ModalMsg 2)
                        (Modal.view
                            { ifClosed = button [ Modal.openOnClick ] [ text "Launch Modal" ]
                            , ifOpen =
                                div []
                                    [ text "Modal content"
                                    , a
                                        (Html.Attributes.href "www.noredink.com"
                                            :: Modal.firstFocusableElement
                                        )
                                        [ text "Go to noredink.come" ]
                                    , button [ Modal.closeOnClick ]
                                        [ text "Close Modal" ]
                                    , a
                                        (Html.Attributes.href "www.noredink.com"
                                            :: Modal.lastFocusableElement
                                        )
                                        [ text "Go to noredink.come" ]
                                    ]
                            }
                            modal
                        )
                    ]

            Nothing ->
                text ""
        ]
