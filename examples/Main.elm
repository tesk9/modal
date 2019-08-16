module Main exposing (main)

import Accessibility.Modal as Modal
import Browser exposing (element)
import Css exposing (..)
import Dict exposing (Dict)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css, href, id)
import Html.Styled.Events exposing (onClick)
import Platform


main : Platform.Program {} Model Msg
main =
    element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view >> toUnstyled
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
                    , viewModalOpener 0
                    , Modal.view (ModalMsg 0)
                        "Single focusable element modal"
                        [ Modal.overlayColor "rgba(128, 0, 128, 0.7)"
                        , Modal.onlyFocusableElementView
                            (\onlyFocusableElement ->
                                div [ css [ displayFlex, justifyContent spaceBetween ] ]
                                    [ text "Modal content"
                                    , button
                                        (onClick (ModalMsg 0 Modal.close)
                                            :: onlyFocusableElement
                                        )
                                        [ text "Close Modal" ]
                                    ]
                            )
                        ]
                        modal
                    ]

            Nothing ->
                text ""
        , case Dict.get 1 model of
            Just modal ->
                section []
                    [ h2 [] [ text "Two focusable elements" ]
                    , viewModalOpener 1
                    , Modal.view (ModalMsg 1)
                        "Two focusable elements modal"
                        [ Modal.overlayColor "rgba(128, 0, 70, 0.7)"
                        , Modal.multipleFocusableElementView
                            (\{ firstFocusableElement, lastFocusableElement } ->
                                div [ css [ displayFlex, justifyContent spaceBetween ] ]
                                    [ text "Modal content"
                                    , button
                                        (onClick (ModalMsg 1 Modal.close) :: firstFocusableElement)
                                        [ text "Close Modal" ]
                                    , a
                                        (href "#" :: lastFocusableElement)
                                        [ text "I'm a link!" ]
                                    ]
                            )
                        ]
                        modal
                    ]

            Nothing ->
                text ""
        , case Dict.get 2 model of
            Just modal ->
                section []
                    [ h2 [] [ text "Three focusable elements" ]
                    , viewModalOpener 2
                    , Modal.view (ModalMsg 2)
                        "Three focusable elements modal"
                        [ Modal.overlayColor "rgba(70, 0, 128, 0.7)"
                        , Modal.autofocusOnLastElement
                        , Modal.multipleFocusableElementView
                            (\{ firstFocusableElement, lastFocusableElement } ->
                                div [ css [ displayFlex, justifyContent spaceBetween ] ]
                                    [ a
                                        (href "#" :: firstFocusableElement)
                                        [ text "I'm a link!" ]
                                    , button [ onClick (ModalMsg 2 Modal.close) ] [ text "Close Modal" ]
                                    , a
                                        (href "#" :: lastFocusableElement)
                                        [ text "I'm a link!" ]
                                    ]
                            )
                        ]
                        modal
                    ]

            Nothing ->
                text ""
        , div
            [ css [ paddingTop (vh 120) ]
            ]
            [ text "Scroll the background to find me" ]
        ]


viewModalOpener : Int -> Html Msg
viewModalOpener uniqueId =
    let
        elementId =
            "modal__launch-element-" ++ String.fromInt uniqueId
    in
    button
        [ id elementId
        , onClick (ModalMsg uniqueId (Modal.open elementId))
        ]
        [ text "Launch Modal" ]
