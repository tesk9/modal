module Modal exposing
    ( Model, init, subscriptions
    , Msg, update
    , view
    )

{-|

@docs Model, init, subscriptions
@docs Msg, update
@docs view

-}

import Accessibility.Key as Key
import Browser
import Browser.Dom exposing (focus)
import Browser.Events
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)
import Task


{-| -}
type Model
    = Opened
    | Closed


{-| -}
init : Model
init =
    Closed


{-| -}
type Msg
    = OpenModal
    | CloseModal
    | Focus String
    | Focused (Result Browser.Dom.Error ())


{-| -}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenModal ->
            ( Opened
            , Cmd.none
            )

        CloseModal ->
            ( Closed
            , Cmd.none
            )

        Focus id ->
            ( model, Task.attempt Focused (focus id) )

        Focused _ ->
            ( model, Cmd.none )


{-| -}
view : Model -> Html Msg
view model =
    div []
        [ button [] [ text "Supports keyboard focus" ]
        , case model of
            Opened ->
                div
                    [ style "border" "2px solid blue"
                    , id "modal"
                    ]
                    [ text "Modal!"
                    , div []
                        [ button
                            [ onClick CloseModal
                            , Key.onKeyDown [ Key.tabBack (Focus "last-button") ]
                            , id "first-button"
                            ]
                            [ text "Close Modal" ]
                        , button
                            [ Key.onKeyDown [ Key.tab (Focus "first-button") ]
                            , id "last-button"
                            ]
                            [ text "other action" ]
                        ]
                    ]

            Closed ->
                button [ onClick OpenModal ] [ text "Open Modal" ]
        , button [] [ text "Supports focus" ]
        ]


{-| -}
subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Opened ->
            Browser.Events.onKeyDown (Key.escape CloseModal)

        Closed ->
            Sub.none
