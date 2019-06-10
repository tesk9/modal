module Modal exposing
    ( Model, init, subscriptions
    , Msg, update
    , view
    , openOnClick, closeOnClick
    , firstFocusableElement, lastFocusableElement, singleFocusableElement
    )

{-|

@docs Model, init, subscriptions
@docs Msg, update
@docs view
@docs openOnClick, closeOnClick
@docs firstFocusableElement, lastFocusableElement, singleFocusableElement

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
view :
    { ifClosed : Html msg
    , ifOpen : Html msg
    }
    -> Model
    -> Html msg
view config model =
    case model of
        Opened ->
            div [ style "border" "1px solid black" ]
                [ config.ifOpen
                ]

        Closed ->
            config.ifClosed


{-| -}
openOnClick : Html.Attribute Msg
openOnClick =
    onClick OpenModal


{-| -}
closeOnClick : Html.Attribute Msg
closeOnClick =
    onClick CloseModal


{-| -}
singleFocusableElement : List (Html.Attribute Msg)
singleFocusableElement =
    [ Key.onKeyDown
        [ Key.tabBack (Focus "modal__single-focusable-element")
        , Key.tab (Focus "modal__single-focusable-element")
        ]
    , id "modal__single-focusable-element"
    ]


{-| -}
firstFocusableElement : List (Html.Attribute Msg)
firstFocusableElement =
    [ Key.onKeyDown [ Key.tabBack (Focus "modal__last-focusable-element") ]
    , id "modal__first-focusable-element"
    ]


{-| -}
lastFocusableElement : List (Html.Attribute Msg)
lastFocusableElement =
    [ Key.onKeyDown [ Key.tab (Focus "modal__first-focusable-element") ]
    , id "modal__last-focusable-element"
    ]


{-| -}
subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Opened ->
            Browser.Events.onKeyDown (Key.escape CloseModal)

        Closed ->
            Sub.none
