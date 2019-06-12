module Main exposing (main)

import Accessibility.Modal as Modal
import Browser exposing (element)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
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
                            Modal.update
                                { dismissOnEscAndOverlayClick = True }
                                modalMsg
                                modal
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
                    , button (Modal.openOnClick identity "0") [ text "Launch Modal" ]
                    , Modal.view
                        { overlayColor = "rgba(128, 0, 128, 0.7)"
                        , modalAttributes = modalAttributes
                        , wrapMsg = identity
                        , title = ( "Single focusable element modal", [] )
                        , content =
                            \{ onlyFocusableElement } ->
                                div [ style "display" "flex", style "justify-content" "space-between" ]
                                    [ text "Modal content"
                                    , button
                                        (onClick Modal.close :: onlyFocusableElement)
                                        [ text "Close Modal" ]
                                    ]
                        }
                        modal
                    ]
                    |> Html.map (ModalMsg 0)

            Nothing ->
                text ""
        , case Dict.get 1 model of
            Just modal ->
                section []
                    [ h2 [] [ text "Two focusable elements" ]
                    , button (Modal.openOnClick identity "1") [ text "Launch Modal" ]
                    , Modal.view
                        { overlayColor = "rgba(128, 0, 70, 0.7)"
                        , modalAttributes = modalAttributes
                        , wrapMsg = identity
                        , title = ( "Two focusable elements modal", [] )
                        , content =
                            \{ firstFocusableElement, lastFocusableElement } ->
                                div [ style "display" "flex", style "justify-content" "space-between" ]
                                    [ text "Modal content"
                                    , button
                                        (onClick Modal.close :: firstFocusableElement)
                                        [ text "Close Modal" ]
                                    , a
                                        (Html.Attributes.href "#" :: lastFocusableElement)
                                        [ text "I'm a link!" ]
                                    ]
                        }
                        modal
                    ]
                    |> Html.map (ModalMsg 1)

            Nothing ->
                text ""
        , case Dict.get 2 model of
            Just modal ->
                section []
                    [ h2 [] [ text "Three focusable elements" ]
                    , button (Modal.openOnClick identity "2") [ text "Launch Modal" ]
                    , Modal.view
                        { overlayColor = "rgba(70, 0, 128, 0.7)"
                        , modalAttributes = modalAttributes
                        , wrapMsg = identity
                        , title = ( "Three focusable elements modal", [] )
                        , content =
                            \{ firstFocusableElement, lastFocusableElement } ->
                                div [ style "display" "flex", style "justify-content" "space-between" ]
                                    [ a
                                        (Html.Attributes.href "#" :: firstFocusableElement)
                                        [ text "I'm a link!" ]
                                    , button [ onClick Modal.close ] [ text "Close Modal" ]
                                    , a
                                        (Html.Attributes.href "#" :: lastFocusableElement)
                                        [ text "I'm a link!" ]
                                    ]
                        }
                        modal
                    ]
                    |> Html.map (ModalMsg 2)

            Nothing ->
                text ""
        , div
            [ style "padding-top" "120vh"
            ]
            [ text "Scroll the background to find me" ]
        ]


modalAttributes : List (Html.Attribute msg)
modalAttributes =
    [ style "background-color" "white"
    , style "border-radius" "8px"
    , style "border" "2px solid purple"
    , style "margin" "80px auto"
    , style "padding" "20px"
    , style "max-width" "600px"
    , style "min-height" "40vh"
    ]
